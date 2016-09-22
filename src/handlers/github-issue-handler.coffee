class GithubIssueHandler
  do: ({ body }, callback) =>
    { repository } = body
    { full_name, open_issues_count } = repository
    [ owner_name, repo_name ] = full_name.split /\//
    metric = { owner_name, repo_name, open_issues_count }
    callback null, metric

module.exports = GithubIssueHandler
