async              = require 'async'
GithubIssueHandler = require './handlers/github-issue-handler'
MochaJsonHandler   = require './handlers/mocha-json-handler'
CodecovIOHandler   = require './handlers/codecov-io-handler'

class Worker
  constructor: (options={})->
    { @db, @redis, @queueName, @queueTimeout } = options
    throw new Error('Worker: requires redis') unless @redis?
    throw new Error('Worker: requires queueName') unless @queueName?
    throw new Error('Worker: requires queueTimeout') unless @queueTimeout?
    @shouldStop = false
    @isStopped = false
    @datastore = @db.metrics
    @handlers =
      'github:issue': new GithubIssueHandler
      'mocha:json': new MochaJsonHandler
      'codecov.io': new CodecovIOHandler

  do: (callback) =>
    @redis.brpop @queueName, @queueTimeout, (error, result) =>
      return callback error if error?
      return callback() unless result?

      [ queue, data ] = result
      try
        data = JSON.parse data
      catch error
        return callback error

      @_process data, callback
    return # avoid returning promise

  run: =>
    async.doUntil @do, (=> @shouldStop), =>
      @isStopped = true

  stop: (callback) =>
    @shouldStop = true

    timeout = setTimeout =>
      clearInterval interval
      callback new Error 'Stop Timeout Expired'
    , 5000

    interval = setInterval =>
      return unless @isStopped?
      clearInterval interval
      clearTimeout timeout
      callback()
    , 250

  _process: (data, callback) =>
    {
      type
      owner_name
      repo_name
      body
    } = data

    handler = @handlers[type]
    unless handler?
      console.error "No Handler Available: #{type}"
      return callback()

    handler.do { owner_name, repo_name, body }, (error, metric) =>
      console.error error.stack if error?
      return callback error if error?
      { owner_name, repo_name } = metric
      dasherized_type = type.replace '.', '-'
      metric.updated_at = "#{dasherized_type}": new Date

      @datastore.update { owner_name, repo_name }, { $set: metric }, { upsert: true }, (error) =>
        return callback error if error?
        callback null, data

module.exports = Worker
