import { useEffect, useState, useRef, useMemo } from "react";

function App() {
  const [messages, setMessages] = useState([]);
  const [isRunning, setIsRunning] = useState(false);
  const [currentTest, setCurrentTest] = useState(null);
  const wsRef = useRef(null);
  const latestStepRef = useRef(null);

  useEffect(() => {
    const url = import.meta?.env?.VITE_WS_URL || "ws://localhost:4000";
    const ws = new WebSocket(url);
    wsRef.current = ws;

    ws.onopen = () => {
      console.log("Connected to CapyDash WebSocket:", url);
    };

    ws.onmessage = (event) => {
      try {
        const parsed = JSON.parse(event.data);
        console.log("📩 React got event:", parsed);
        console.log("📩 Event type:", parsed.type, "Step name:", parsed.step_name, "Test name:", parsed.test_name);

        // Track running state based on runner events
        if (parsed.type === "runner") {
          if (parsed.line && parsed.line.includes("Finished")) {
            setIsRunning(false);
            setCurrentTest(null);
          } else if (parsed.line && !parsed.line.includes("Finished")) {
            setIsRunning(true);
          }
        }

        // Track current test for step events
        if (parsed.test_name && parsed.type !== "runner") {
          setCurrentTest(parsed.test_name);
        }

        setMessages((prev) => {
          const newMessages = [parsed, ...prev];
          console.log("📩 Total messages now:", newMessages.length);
          return newMessages;
        });
      } catch (e) {
        console.warn("Non-JSON message:", event.data);
        setMessages((prev) => [...prev, event.data]);
      }
    };

    ws.onerror = (err) => {
      console.warn("WebSocket error:", err);
    };

    ws.onclose = () => {
      console.log("Disconnected from CapyDash WebSocket:", url);
    };

    return () => ws.close();
  }, []);

  // Auto-scroll to latest step during test execution
  useEffect(() => {
    if (isRunning && latestStepRef.current) {
      latestStepRef.current.scrollIntoView({
        behavior: 'smooth',
        block: 'nearest'
      });
    }
  }, [messages, isRunning]);

  // Group by test class, then by test method, then by steps
  const grouped = useMemo(() => {
    console.log("🔄 Regrouping messages:", messages.length);
    const byTestClass = new Map();
    let unassigned = 0;

    for (const msg of messages) {
      const evt = typeof msg === "string" ? null : msg;
      if (!evt) continue;

      if (evt.type === "runner") continue; // ignore runner output

      console.log("🔍 Processing event:", evt);

      if (!evt.test_name) {
        console.log("❌ No test_name, but including anyway:", evt);
        const testClass = "UnknownTest";
        if (!byTestClass.has(testClass)) byTestClass.set(testClass, new Map());
        byTestClass.get(testClass).set("unknown_method", [evt]);
        continue;
      }

      console.log("🔍 Processing event with test_name:", evt.test_name, "Type:", evt.type, "Has #:", evt.test_name.includes('#'));

      // Extract test class and method name dynamically
      let testClass, testMethod;
      if (evt.test_name.includes('#')) {
        // Format: "ClassName#method_name" - split on the first #
        [testClass, testMethod] = evt.test_name.split('#', 2);
      } else if (evt.test_name.startsWith('test_')) {
        // Format: "test_something_something" - this is a method name without class context
        // We need to infer the class name from the method name or use a generic approach
        testMethod = evt.test_name;

        // Try to extract meaningful words from the test method name to create a class name
        const testParts = evt.test_name.replace('test_', '').split('_');

        // Look for common patterns that might indicate the test domain
        let domainHint = '';

        // Define domain patterns more comprehensively
        const domainPatterns = {
          'Navigation': ['page', 'loads', 'elements', 'state', 'navigation', 'ui', 'view', 'render', 'display', 'show', 'hide'],
          'ErrorHandling': ['error', 'handles', 'empty', 'special', 'html', 'validation', 'invalid', 'exception', 'fail', 'catch'],
          'Homepage': ['homepage', 'welcome', 'landing', 'index', 'main', 'root'],
          'UserFlow': ['user', 'flow', 'complete', 'multiple', 'workflow', 'process', 'journey', 'experience'],
          'Api': ['api', 'functionality', 'endpoint', 'request', 'response', 'service', 'client'],
          'Example': ['failing', 'shows', 'example', 'demo', 'sample', 'test'],
          'Form': ['form', 'input', 'submit', 'field', 'validation', 'data'],
          'Authentication': ['auth', 'login', 'logout', 'session', 'token', 'password', 'signin', 'signout'],
          'Database': ['db', 'database', 'model', 'record', 'save', 'create', 'update', 'delete'],
          'Integration': ['integration', 'feature', 'e2e', 'end', 'to', 'end']
        };

        // Find the best matching domain
        let bestMatch = '';
        let maxMatches = 0;

        for (const [domain, patterns] of Object.entries(domainPatterns)) {
          const matches = testParts.filter(part => patterns.some(pattern =>
            part.includes(pattern) || pattern.includes(part)
          )).length;

          if (matches > maxMatches) {
            maxMatches = matches;
            bestMatch = domain;
          }
        }

        if (bestMatch) {
          domainHint = bestMatch;
        } else {
          // Generic approach: use the first 2-3 meaningful words from the method name
          const meaningfulParts = testParts.filter(part => part.length > 2).slice(0, 2);
          domainHint = meaningfulParts.map(part => part.charAt(0).toUpperCase() + part.slice(1)).join('');
        }

        testClass = domainHint + 'Test';
      } else {
        // Assume the entire test_name is the class name
        testClass = evt.test_name;
        testMethod = "unknown_method";
      }

      // Initialize nested structure
      if (!byTestClass.has(testClass)) byTestClass.set(testClass, new Map());
      if (!byTestClass.get(testClass).has(testMethod)) byTestClass.get(testClass).set(testMethod, []);

      byTestClass.get(testClass).get(testMethod).push(evt);
    }

    const result = [];

    // Convert to hierarchical structure
    for (const [testClass, methods] of byTestClass.entries()) {
      const testMethods = [];
      for (const [methodName, steps] of methods.entries()) {
        // Dedupe steps within each method and reverse to show chronologically
        const seen = new Set();
        const dedupedSteps = [];
        for (const step of steps) {
          const key = `${step.step_name || ""}:${step.detail || ""}`;
          if (seen.has(key)) continue;
          seen.add(key);
          dedupedSteps.push(step);
        }
        // Reverse to show first steps at top, last steps at bottom
        testMethods.push({ methodName, steps: dedupedSteps.reverse() });
      }
      result.push({ testClass, testMethods });
    }

    if (unassigned > 0) {
      result.push({ testClass: "(Unassigned)", testMethods: [], unassigned });
    }
    console.log("🔄 Grouped result:", result.length, "test classes");
    return result;
  }, [messages]);

  const runTestFile = (testFile) => {
    const ws = wsRef.current;
    if (!ws || ws.readyState !== WebSocket.OPEN) return;

    // Clear previous test results and set running state
    setMessages([]);
    setIsRunning(true);
    setCurrentTest(testFile);
    console.log(`🧹 Cleared messages, starting fresh test run for: ${testFile}`);

    // Dynamic test file mapping - automatically generates file paths from class names
    const generateTestFilePath = (className) => {
      // Convert class name to snake_case file name
      const snakeCase = className
        .replace(/([A-Z])/g, '_$1')
        .toLowerCase()
        .replace(/^_/, '');

      // Determine if it's a system test or integration test based on common patterns
      if (className.includes('System') || className.includes('SystemTest')) {
        return `test/system/${snakeCase}.rb`;
      } else if (className.includes('Integration') || className.includes('Feature') || className.includes('Flow')) {
        return `test/features/${snakeCase}.rb`;
      } else if (className.includes('Controller')) {
        return `test/controllers/${snakeCase}.rb`;
      } else if (className.includes('Model')) {
        return `test/models/${snakeCase}.rb`;
      } else {
        // Default to system tests for unknown patterns
        return `test/system/${snakeCase}.rb`;
      }
    };

    // Generate test file path dynamically for any class name
    const actualTestPath = generateTestFilePath(testFile);

    console.log(`🔍 Generated test path for ${testFile}: ${actualTestPath}`);

    if (!actualTestPath) {
      console.error(`Unknown test file: ${testFile}`);
      setIsRunning(false);
      setCurrentTest(null);
      return;
    }
    console.log(`Running test: ${actualTestPath}`);
    ws.send(JSON.stringify({ command: "run_tests", args: ["bundle", "exec", "rails", "test", actualTestPath] }));
  };


  const runAllSystemTests = () => {
    const ws = wsRef.current;
    if (!ws || ws.readyState !== WebSocket.OPEN) return;

    // Clear previous test results and set running state
    setMessages([]);
    setIsRunning(true);
    setCurrentTest("All System Tests");
    console.log(`🧹 Cleared messages, starting fresh test run (all tests)`);

    ws.send(JSON.stringify({ command: "run_tests", args: ["bundle", "exec", "rails", "test", "test/system"] }));
  };

  return (
    <div style={{ padding: "1rem", maxWidth: 1400, margin: "0 auto", fontFamily: "Inter, system-ui, -apple-system, Segoe UI, Roboto" }}>
      <h1 style={{ fontSize: 24, margin: 0, paddingBottom: 12, borderBottom: "2px solid #eee" }}>CapyDash</h1>
      <div style={{ fontSize: 14, color: "#666", marginBottom: 12 }}>
        Last update: {new Date().toLocaleTimeString()} | Messages: {messages.length} | Groups: {grouped.length}
        {isRunning && (
          <span style={{ color: "#007bff", fontWeight: "bold", marginLeft: 12 }}>
            🔄 Running: {currentTest}
          </span>
        )}
      </div>
      <div style={{ display: "flex", gap: 24, marginTop: 16 }}>
        <div style={{ flex: 3 }}>
          <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 8 }}>
            <strong>Test Files</strong>
            <span style={{ fontSize: 12, color: "#666" }}>{grouped.length} files</span>
          </div>
          <ul style={{ listStyle: "none", padding: 0, margin: 0 }}>
            {messages.length === 0 && !isRunning ? (
              <li style={{ color: "#666" }}>Waiting for test events…</li>
            ) : isRunning && messages.length === 0 ? (
              <li style={{ color: "#007bff", padding: "1rem", border: "1px solid #007bff", borderRadius: 6, background: "#f0f8ff" }}>
                🔄 Starting test: {currentTest}...
                <div style={{ fontSize: 11, color: "#666", marginTop: 4 }}>
                  Waiting for test events... Check console for debugging info.
                </div>
              </li>
            ) : (
              grouped.map((group, gi) => {
                if (group.unassigned) {
                  return (
                    <li key={gi} style={{ marginBottom: 8, border: "1px solid #eee", borderRadius: 6, padding: 8, background: "#f5f5f5" }}>
                      <strong>{group.testClass}</strong> <span style={{ fontSize: 12, color: "#666" }}>({group.unassigned} events)</span>
                    </li>
                  );
                }

                // Calculate overall status for the test class
                const allSteps = group.testMethods.flatMap(method => method.steps);
                const testResult = allSteps.find(e => e.step_name === "test_result");
                const latestStatus = testResult ? testResult.status :
                  (allSteps.find(e => e.status === "failed") ? "failed" :
                   (allSteps.some(e => e.status === "passed") ? "passed" : "running"));

                // Check if this is the currently running test
                const isCurrentlyRunning = isRunning && currentTest &&
                  (currentTest === group.testClass ||
                   (currentTest === "All System Tests" && allSteps.length > 0));

                const headerBg = latestStatus === "failed" ? "#ffecec" :
                  (latestStatus === "passed" ? "#e6ffed" :
                   (isCurrentlyRunning ? "#e6f3ff" : "#f5f5f5"));

                return (
                  <li key={gi} style={{ marginBottom: 12, border: "1px solid #eee", borderRadius: 8, boxShadow: "0 2px 4px rgba(0,0,0,0.1)" }}>
                    <details open>
                      <summary style={{ cursor: "pointer", padding: 16, background: headerBg, borderBottom: "1px solid #eee", borderTopLeftRadius: 8, borderTopRightRadius: 8 }}>
                        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                          <div>
                            <strong style={{ marginRight: 12, fontSize: 16 }}>{group.testClass}</strong>
                            {isCurrentlyRunning ? (
                              <span style={{ fontSize: 12, fontWeight: 600, color: "#007bff", background: "#e6f3ff", padding: "4px 8px", borderRadius: 4 }}>🔄 RUNNING</span>
                            ) : (
                              <span style={{
                                fontSize: 12,
                                fontWeight: 600,
                                padding: "4px 8px",
                                borderRadius: 4,
                                background: latestStatus === "passed" ? "#e6ffed" : latestStatus === "failed" ? "#ffecec" : "#f5f5f5",
                                color: latestStatus === "passed" ? "#2d5a2d" : latestStatus === "failed" ? "#b00020" : "#666"
                              }}>
                                {latestStatus.toUpperCase()}
                              </span>
                            )}
                            <span style={{ fontSize: 12, color: "#666", marginLeft: 12 }}>{group.testMethods.length} methods</span>
                          </div>
                          <button
                            onClick={(e) => { e.stopPropagation(); runTestFile(group.testClass); }}
                            disabled={isRunning}
                            style={{
                              fontSize: 11,
                              padding: "4px 8px",
                              borderRadius: 4,
                              border: "1px solid #ddd",
                              cursor: isRunning ? "not-allowed" : "pointer",
                              background: "white",
                              opacity: isRunning ? 0.6 : 1
                            }}
                          >
                            {isRunning && isCurrentlyRunning ? "🔄 Running" : "Run"}
                          </button>
                        </div>
                      </summary>
                      <div style={{ padding: 12 }}>
                        {group.testMethods.map((method, mi) => {
                          const methodSteps = method.steps;
                          const methodStatus = methodSteps.find(e => e.status === "failed") ? "failed" :
                            (methodSteps.some(e => e.status === "passed") ? "passed" : "running");
                          const methodBg = methodStatus === "failed" ? "#ffecec" :
                            (methodStatus === "passed" ? "#e6ffed" : "#f5f5f5");

                          return (
                            <details key={mi} style={{ marginBottom: 8, border: "1px solid #ddd", borderRadius: 6, background: methodBg }}>
                              <summary style={{ cursor: "pointer", padding: 12, background: methodBg, borderBottom: "1px solid #ddd", borderRadius: 6 }}>
                                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                                  <div>
                                    <strong style={{ fontSize: 14 }}>{method.methodName}</strong>
                                    <span style={{
                                      fontSize: 11,
                                      fontWeight: 600,
                                      padding: "2px 6px",
                                      borderRadius: 3,
                                      marginLeft: 8,
                                      background: methodStatus === "passed" ? "#e6ffed" : methodStatus === "failed" ? "#ffecec" : "#f5f5f5",
                                      color: methodStatus === "passed" ? "#2d5a2d" : methodStatus === "failed" ? "#b00020" : "#666"
                                    }}>
                                      {methodStatus.toUpperCase()}
                                    </span>
                                    <span style={{ fontSize: 11, color: "#666", marginLeft: 8 }}>{methodSteps.length} steps</span>
                                  </div>
                                </div>
                              </summary>
                              <ul style={{ listStyle: "none", padding: 8, margin: 0 }}>
                                {methodSteps.map((evt, i) => {
                                  const isStepRunning = evt?.status === "running" || (!evt?.status && isCurrentlyRunning);
                                  const isLatestStep = i === 0 && isCurrentlyRunning;
                                  const statusColor = evt?.status === "passed" ? "#e6ffed" :
                                    evt?.status === "failed" ? "#ffecec" :
                                    isStepRunning ? "#e6f3ff" : "#f5f5f5";
                                  return (
                                    <li
                                      key={i}
                                      ref={isLatestStep ? latestStepRef : null}
                                      style={{
                                        margin: "0.5rem 0",
                                        padding: "0.75rem",
                                        border: "1px solid #eee",
                                        background: statusColor,
                                        borderRadius: 6,
                                        borderLeft: isStepRunning ? "3px solid #007bff" : "3px solid transparent",
                                        boxShadow: "0 1px 2px rgba(0,0,0,0.1)"
                                      }}>
                                      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 6 }}>
                                        <strong style={{ fontSize: 13 }}>{evt.step_name}</strong>
                                        {isStepRunning ? (
                                          <span style={{ fontSize: 11, fontWeight: 600, color: "#007bff", background: "#e6f3ff", padding: "2px 6px", borderRadius: 3 }}>🔄 RUNNING</span>
                                        ) : (
                                          <span style={{
                                            fontSize: 11,
                                            fontWeight: 600,
                                            padding: "2px 6px",
                                            borderRadius: 3,
                                            background: evt?.status === "passed" ? "#e6ffed" : evt?.status === "failed" ? "#ffecec" : "#f5f5f5",
                                            color: evt?.status === "passed" ? "#2d5a2d" : evt?.status === "failed" ? "#b00020" : "#666"
                                          }}>
                                            {evt.status?.toUpperCase?.() || "PENDING"}
                                          </span>
                                        )}
                                      </div>
                                      {evt.detail && (
                                        <div style={{ marginTop: 6, color: "#444", fontSize: 12, fontFamily: "monospace" }}>{evt.detail}</div>
                                      )}
                                      {(evt.data_url || evt.screenshot) && (
                                        <div style={{ marginTop: 8 }}>
                                          <img src={evt.data_url || `/${evt.screenshot}`} alt="screenshot" style={{ maxWidth: "100%", border: "1px solid #ddd", borderRadius: 4 }} />
                                        </div>
                                      )}
                                      {evt.error && (
                                        <div style={{ marginTop: 8 }}>
                                          <div style={{ fontSize: 11, fontWeight: 600, marginBottom: 4, color: "#b00020" }}>Error Details</div>
                                          <pre style={{
                                            margin: 0,
                                            color: "#b00020",
                                            background: "#fff5f5",
                                            padding: 8,
                                            borderRadius: 4,
                                            overflowX: "auto",
                                            fontSize: 11,
                                            border: "1px solid #ffebee"
                                          }}>{evt.error}</pre>
                                        </div>
                                      )}
                                    </li>
                                  );
                                })}
                              </ul>
                            </details>
                          );
                        })}
                      </div>
                    </details>
                  </li>
                );
              })
            )}
          </ul>
        </div>
        <div style={{ flex: 1 }}>
          <div style={{ padding: 12, border: "1px solid #eee", borderRadius: 6, marginBottom: 12 }}>
            <div style={{ fontWeight: 600, marginBottom: 6 }}>Connection</div>
            <div style={{ fontSize: 12, color: "#555" }}>WS URL: {import.meta?.env?.VITE_WS_URL || "ws://localhost:4000"}</div>
            <div style={{ fontSize: 12, color: "#555", marginTop: 6 }}>Refresh the page to see recent events (server replays last 100).</div>
          </div>
          <div style={{ padding: 12, border: "1px solid #eee", borderRadius: 6 }}>
            <div style={{ fontWeight: 600, marginBottom: 6 }}>Runner</div>
            <button
              onClick={runAllSystemTests}
              disabled={isRunning}
              style={{
                fontSize: 13,
                padding: "6px 10px",
                borderRadius: 4,
                border: "1px solid #ddd",
                cursor: isRunning ? "not-allowed" : "pointer",
                background: isRunning ? "#6c757d" : "#007bff",
                color: "white",
                marginBottom: 8,
                opacity: isRunning ? 0.6 : 1
              }}
            >
              {isRunning ? "🔄 Running Tests..." : "Run All System Tests"}
            </button>
            <div style={{ fontSize: 12, color: "#555" }}>Each test file can also be run individually using the "Run" button next to its name.</div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default App;
