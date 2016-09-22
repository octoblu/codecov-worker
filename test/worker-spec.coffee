Worker  = require '../src/worker'
Redis   = require 'ioredis'
RedisNS = require '@octoblu/redis-ns'

describe 'Worker', ->
  beforeEach (done) ->
    client = new Redis 'localhost', dropBufferSupport: true
    client.on 'ready', =>
      @redis = new RedisNS 'test-worker', client
      done()

  beforeEach ->
    queueName = 'work'
    queueTimeout = 1
    @sut = new Worker { @redis, queueName, queueTimeout }

  afterEach (done) ->
    @sut.stop done

  describe '->do', ->
    beforeEach (done) ->
      data = JSON.stringify foo: 'bar'
      @redis.lpush 'work', data, done
      return # stupid promises

    beforeEach (done) ->
      @sut.do (error, @data) =>
        done error

    it 'should call the callback with data', ->
      expect(@data).to.deep.equal foo: 'bar'