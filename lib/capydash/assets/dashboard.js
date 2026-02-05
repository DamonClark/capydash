function openLightbox(src) {
    var lightbox = document.getElementById('screenshotLightbox');
    var img = document.getElementById('lightboxImage');
    if (lightbox && img) {
        img.src = src;
        lightbox.classList.add('active');
    }
}

function closeLightbox() {
    var lightbox = document.getElementById('screenshotLightbox');
    if (lightbox) {
        lightbox.classList.remove('active');
    }
}

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        closeLightbox();
    }
});

function toggleTestMethod(safeId) {
    const stepsContainer = document.getElementById('steps-' + safeId);
    const button = document.querySelector('[onclick*="' + safeId + '"]');

    if (stepsContainer && button) {
        const icon = button.querySelector('.expand-icon');
        if (icon) {
            const isCollapsed = stepsContainer.classList.contains('collapsed');

            if (isCollapsed) {
                stepsContainer.classList.remove('collapsed');
                icon.textContent = '\u25BC';
            } else {
                stepsContainer.classList.add('collapsed');
                icon.textContent = '\u25B6';
            }
        }
    }
}

// Search functionality
document.addEventListener('DOMContentLoaded', function() {
    const searchInput = document.getElementById('searchInput');
    if (!searchInput) return;

    searchInput.addEventListener('input', function(e) {
        const query = e.target.value.toLowerCase().trim();
        const testMethods = document.querySelectorAll('.test-method');
        const testClasses = document.querySelectorAll('.test-class');

        // Determine if query is a status filter
        const isStatusFilter = query === 'pass' || query === 'fail' ||
                              query === 'passed' || query === 'failed' ||
                              query === 'pending';

        testMethods.forEach(function(method) {
            const name = method.getAttribute('data-name') || '';
            const status = method.getAttribute('data-status') || '';

            let shouldShow = false;

            if (!query) {
                // No query - show all
                shouldShow = true;
            } else if (isStatusFilter) {
                // Status filter - check status
                shouldShow = (query === 'pass' && status === 'passed') ||
                            (query === 'fail' && status === 'failed') ||
                            query === status;
            } else {
                // Name filter - check if name contains query
                shouldShow = name.includes(query);
            }

            if (shouldShow) {
                method.classList.remove('hidden');
            } else {
                method.classList.add('hidden');
            }
        });

        // Hide test classes if all methods are hidden
        testClasses.forEach(function(testClass) {
            const visibleMethods = testClass.querySelectorAll('.test-method:not(.hidden)');
            if (visibleMethods.length === 0) {
                testClass.classList.add('hidden');
            } else {
                testClass.classList.remove('hidden');
            }
        });
    });
});
