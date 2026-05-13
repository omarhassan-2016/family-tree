class HealthController < ApplicationController
  def index
    @scan_results = Tree::HealthScanner.scan
    @total_issues = @scan_results.values.sum(&:count)
  end
end
