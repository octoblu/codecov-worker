class GithubIssueHandler
  do: ({ body }, callback) =>
    try
      { repository } = body
      { full_name, open_issues_count } = repository
      [ owner_name, repo_name ] = full_name.split /\//
    catch error
      return callback error

    metric = {
      owner_name
      repo_name
      open_issues_count
    }
    callback null, metric

module.exports = GithubIssueHandler
