chalk        = require 'chalk'
dashdash      = require 'dashdash'
Redis         = require 'ioredis'
RedisNS       = require '@octoblu/redis-ns'
Worker        = require './src/worker'
mongojs       = require 'mongojs'
net           = require 'net'

packageJSON = require './package.json'

OPTIONS = [
  {
    names: ['healthcheck-uri', 'u']
    type: 'string'
    env: 'HEALTHCHECK_URI'
    default: './worker.sock'
    help: 'Healthcheck URI'
  }
]

class Command
  constructor: ->
    process.on 'uncaughtException', @die
    {
      @healthcheck_uri
    } = @parseOptions()

  parseOptions: =>
    parser = dashdash.createParser({options: OPTIONS})
    options = parser.parse(process.argv)

    if options.help
      console.log "usage: codecov-worker [OPTIONS]\noptions:\n#{parser.help({includeEnv: true})}"
      process.exit 0

    if options.version
      console.log packageJSON.version
      process.exit 0

    unless options.healthcheck_uri?
      console.error "usage: codecov-worker [OPTIONS]\noptions:\n#{parser.help({includeEnv: true})}"
      console.error chalk.red 'Missing required parameter --healthcheck-uri, -u, or env: HEALTHCHECK_URI' unless options.healthcheck_uri?
      process.exit 1

    return options

  run: =>
    client = net.createConnection @healthcheck_uri
    client.on 'connect', =>
      client.write 'HEALTHCHECK'

    client.on 'data', (data) =>
      data = data.toString()
      return @die new Error('Healthcheck failed') unless data == 'OK'
      process.exit 0

  die: (error) =>
    return process.exit(0) unless error?
    console.error 'ERROR'
    console.error error.stack
    process.exit 1

module.exports = Command
