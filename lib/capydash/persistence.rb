require 'json'
require 'fileutils'

module CapyDash
  class Persistence
    class << self
      def save_test_run(test_run_data)
        ensure_data_directory
        file_path = test_run_file_path(test_run_data[:id] || generate_run_id)

        begin
          File.write(file_path, JSON.pretty_generate(test_run_data))
          file_path
        rescue => e
          ErrorHandler.handle_error(e, {
            error_type: 'persistence',
            operation: 'save_test_run',
            run_id: test_run_data[:id]
          })
          nil
        end
      end

      def load_test_run(run_id)
        file_path = test_run_file_path(run_id)
        return nil unless File.exist?(file_path)

        begin
          JSON.parse(File.read(file_path), symbolize_names: true)
        rescue => e
          ErrorHandler.handle_error(e, {
            error_type: 'persistence',
            operation: 'load_test_run',
            run_id: run_id
          })
          nil
        end
      end

      def list_test_runs(limit = 50)
        ensure_data_directory
        data_dir = data_directory

        begin
          Dir.glob(File.join(data_dir, "test_run_*.json"))
            .sort_by { |f| File.mtime(f) }
            .reverse
            .first(limit)
            .map do |file_path|
              run_id = File.basename(file_path, '.json').gsub('test_run_', '')
              {
                id: run_id,
                file_path: file_path,
                created_at: File.mtime(file_path),
                size: File.size(file_path)
              }
            end
        rescue => e
          ErrorHandler.handle_error(e, {
            error_type: 'persistence',
            operation: 'list_test_runs'
          })
          []
        end
      end

      def delete_test_run(run_id)
        file_path = test_run_file_path(run_id)
        return false unless File.exist?(file_path)

        begin
          File.delete(file_path)
          Logger.info("Test run deleted", { run_id: run_id })
          true
        rescue => e
          ErrorHandler.handle_error(e, {
            error_type: 'persistence',
            operation: 'delete_test_run',
            run_id: run_id
          })
          false
        end
      end

      def cleanup_old_runs(days_to_keep = 30)
        ensure_data_directory
        cutoff_time = Time.now - (days_to_keep * 24 * 60 * 60)
        deleted_count = 0

        begin
          Dir.glob(File.join(data_directory, "test_run_*.json")).each do |file_path|
            if File.mtime(file_path) < cutoff_time
              run_id = File.basename(file_path, '.json').gsub('test_run_', '')
              if delete_test_run(run_id)
                deleted_count += 1
              end
            end
          end

          Logger.info("Cleanup completed", {
            deleted_runs: deleted_count,
            days_kept: days_to_keep
          })

          deleted_count
        rescue => e
          ErrorHandler.handle_error(e, {
            error_type: 'persistence',
            operation: 'cleanup_old_runs'
          })
          0
        end
      end

      private

      def data_directory
        @data_directory ||= File.join(Dir.pwd, "tmp", "capydash_data")
      end

      def ensure_data_directory
        FileUtils.mkdir_p(data_directory) unless Dir.exist?(data_directory)
      end

      def test_run_file_path(run_id)
        File.join(data_directory, "test_run_#{run_id}.json")
      end

      def generate_run_id
        "#{Time.now.to_i}_#{SecureRandom.hex(4)}"
      end
    end
  end
end
