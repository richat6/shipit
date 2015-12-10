fs = require 'fs'
assert = require 'assert'
should = require('chai').should()
expect = require('chai').expect
bond = require 'bondjs'
moment = require 'moment-timezone'
{AusPostClient} = require '../lib/auspost'
{ShipperClient} = require '../lib/shipper'

describe "auspost client", ->
  _auspostClient = null

  before ->
    _auspostClient = new AusPostClient
      username: 'ozzie ozzie ozzie'
      password: 'oi oi oi'

  describe "requestOptions", ->
    _options = null

    before ->
      _options = _auspostClient.requestOptions trackingNumber: '4NW000011501000600203'

    it "creates a GET request", ->
      _options.method.should.equal 'GET'

    it "uses the correct URL", ->
      _options.uri.should.equal "https://digitalapi.auspost.com.au/track/v3/search?q=4NW000011501000600203"

  describe "validateResponse", ->

  describe "integration tests", ->
    _package = null

    describe "en-route package", ->
      before (done) ->
        fs.readFile 'test/stub_data/auspost_enroute.json', 'utf8', (err, doc) ->
          _auspostClient.presentResponse doc, 'trk', (err, resp) ->
            should.not.exist(err)
            _package = resp
            done()

      it "has a status of delivered", ->
        expect(_package.status).to.equal ShipperClient.STATUS_TYPES.EN_ROUTE

      it "has a service of eParcel", ->
        expect(_package.service).to.equal "eParcel"

      it "has a destination of Australia", ->
        expect(_package.destination).to.equal "Australia"

      it "has an ETA of 18 Nov 2013", ->
        expect(_package.eta).to.deep.equal new Date '2013-11-18T23:59:59Z'

      it "has eleven activities with timestamp and details", ->
        expect(_package.activities).to.have.length 11
        act = _package.activities[0]
        expect(act.timestamp).to.deep.equal new Date '2014-07-09T01:43:13Z'
        expect(act.location).to.equal 'Milton, QLD'
        expect(act.details).to.equal 'Customer Enquiry lodged'
        act = _package.activities[10]
        expect(act.timestamp).to.deep.equal new Date '2013-11-08T00:29:15Z'
        expect(act.location).to.equal null
        expect(act.details).to.equal 'Shipping information received by Australia Post'

