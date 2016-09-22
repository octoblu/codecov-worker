class MochaJsonHandler
  do: ({ owner_name, repo_name, body }, callback) =>
    { stats } = body
    { tests, passes, failures, pending, duration } = stats
    metric = {
      owner_name
      repo_name
      test_cases_count: tests
      passing_test_cases_count: passes
      failing_test_cases_count: failures
      pending_test_cases_count: pending
      test_cases_duration_ms: duration
    }
    callback null, metric

module.exports = MochaJsonHandler
