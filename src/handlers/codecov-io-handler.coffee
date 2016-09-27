class CodecovIOError
  do: ({ body }, callback) =>
    try
      { owner, repo, head } = body
      { totals } = head
    catch error
      return callback error

    owner_name             = owner.username
    repo_name              = repo.name
    total_lines_count      = totals.n
    lines_covered_count    = totals.h
    lines_missed_count     = totals.m
    branches_covered_count = totals.b
    coverage_ratio         = totals.c

    metric = {
      owner_name
      repo_name
      total_lines_count
      lines_covered_count
      lines_missed_count
      branches_covered_count
      coverage_ratio
    }
    callback null, metric

module.exports = CodecovIOError
