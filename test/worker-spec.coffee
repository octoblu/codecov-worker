Worker  = require '../src/worker'
Redis   = require 'ioredis'
RedisNS = require '@octoblu/redis-ns'
mongojs = require 'mongojs'

describe 'Worker', ->
  beforeEach (done) ->
    client = new Redis 'localhost', dropBufferSupport: true
    client.on 'ready', =>
      @redis = new RedisNS 'test-worker', client
      @redis.del 'work', done

  beforeEach (done) ->
    @db = mongojs 'localhost', ['metrics']
    @datastore = @db.metrics
    @db.metrics.remove done

  beforeEach ->
    queueName = 'work'
    queueTimeout = 1
    @sut = new Worker { @db, @redis, queueName, queueTimeout }

  afterEach (done) ->
    @sut.stop done

  describe '->do', ->
    context 'github:issue', ->
      beforeEach (done) ->
        data =
          type: 'github:issue'
          body:
            repository:
              open_issues_count: 1
              full_name: 'octoblu/something'

        record = JSON.stringify data
        @redis.lpush 'work', record, done
        return # stupid promises

      beforeEach (done) ->
        @sut.do done

      it 'should create a metric', (done) ->
        @datastore.findOne owner_name: 'octoblu', repo_name: 'something', (error, metric) =>
          return done error if error?
          expectedMetric =
            owner_name: 'octoblu'
            repo_name: 'something'
            open_issues_count: 1

          expect(metric).to.containSubset expectedMetric
          done()

    context 'mocha:json', ->
      beforeEach (done) ->
        data =
          type: 'mocha:json'
          owner_name: 'octoblu'
          repo_name: 'othing'
          body:
            passes: 1
            pending: 1
            failures: 1
            tests: 3
            duration: 55

        record = JSON.stringify data
        @redis.lpush 'work', record, done
        return # stupid promises

      beforeEach (done) ->
        @sut.do done

      it 'should create a metric', (done) ->
        @datastore.findOne owner_name: 'octoblu', repo_name: 'othing', (error, metric) =>
          return done error if error?
          expectedMetric =
            owner_name: 'octoblu'
            repo_name: 'othing'
            test_cases_count: 3
            pending_test_cases_count: 1
            failing_test_cases_count: 1
            passing_test_cases_count: 1
            test_cases_duration_ms: 55

          expect(metric).to.containSubset expectedMetric
          done()

    context 'codecov.io', ->
      beforeEach (done) ->
        data =
          type: 'codecov.io'
          owner_name: 'octoblu'
          repo_name: 'wathing'
          body:
            head:
              totals:
                n: 5
                h: 2
                m: 1
                c: 50.00
                b: 3
            owner:
              username: 'octoblu'
            repo:
              name:
                'wathing'

        record = JSON.stringify data
        @redis.lpush 'work', record, done
        return # stupid promises

      beforeEach (done) ->
        @sut.do done

      it 'should create a metric', (done) ->
        @datastore.findOne owner_name: 'octoblu', repo_name: 'wathing', (error, metric) =>
          return done error if error?
          expectedMetric =
            owner_name: 'octoblu'
            repo_name: 'wathing'
            total_lines_count: 5
            lines_covered_count: 2
            lines_missed_count: 1
            branches_covered_count: 3
            coverage_ratio: 50.00

          expect(metric).to.containSubset expectedMetric
          done()
