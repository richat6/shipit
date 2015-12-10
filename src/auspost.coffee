{reduce} = require 'underscore'
moment = require 'moment-timezone'
{titleCase} = require 'change-case'
{ShipperClient} = require './shipper'

class AusPostClient extends ShipperClient

  constructor: (@options) ->
    super

  validateResponse: (response, cb) ->
    response = JSON.parse response
    return cb(error: 'missing events') unless response['QueryTrackEventsResponse']?['TrackingResults']?[0]?['Consignment']?['Articles']?[0]?['Events']?
    cb null, response

  STATUS_MAP =
    "Pending": ShipperClient.STATUS_TYPES.OUT_FOR_DELIVERY,
    "Initiated": ShipperClient.STATUS_TYPES.SHIPPING,
    "Manifested": ShipperClient.STATUS_TYPES.SHIPPING,
    "Lodged": ShipperClient.STATUS_TYPES.SHIPPING,
    "In transit": ShipperClient.STATUS_TYPES.EN_ROUTE,
    "Accepted by driver": ShipperClient.STATUS_TYPES.EN_ROUTE,
    "Onboard with driver": ShipperClient.STATUS_TYPES.EN_ROUTE,
    "Transferred": ShipperClient.STATUS_TYPES.SHIPPING,
    "Estimated delivery by": ShipperClient.STATUS_TYPES.EN_ROUTE,
    "Awaiting collection": ShipperClient.STATUS_TYPES.DELAYED, 
    "Delivered": ShipperClient.STATUS_TYPES.DELIVERED,
    "Possible delay": ShipperClient.STATUS_TYPES.DELAYED, 
    "Unsuccessful pickup": ShipperClient.STATUS_TYPES.DELAYED, 
    "Attempted delivery": ShipperClient.STATUS_TYPES.DELAYED, 
    "Undeliverable": ShipperClient.STATUS_TYPES.DELAYED, 
    "Despatched": ShipperClient.STATUS_TYPES.EN_ROUTE,
    "Processing": ShipperClient.STATUS_TYPES.EN_ROUTE,
    "Returned": ShipperClient.STATUS_TYPES.DELAYED,
    "Returning to sender": ShipperClient.STATUS_TYPES.DELAYED,  
    "Started": ShipperClient.STATUS_TYPES.SHIPPING,
    "Not compliant": ShipperClient.STATUS_TYPES.DELAYED,
    "Unknown": ShipperClient.STATUS_TYPES.UNKNOWN, 
    "Contact sender": ShipperClient.STATUS_TYPES.DELAYED

  presentStatus: (eventType) ->
    STATUS_MAP[eventType] if eventType?

  getArticle: (shipment) ->
    shipment['QueryTrackEventsResponse']?['TrackingResults']?[0]?['Consignment']?['Articles']?[0]

  getActivitiesAndStatus: (shipment) ->
    activities = []
    article = @getArticle shipment
    status = null
    rawActivities = article?['Events']
    for rawActivity in rawActivities or []
      location = rawActivity['Location'] ? null
      dateTime = rawActivity['EventDateTime']
      timestamp = new Date(parseInt(dateTime)) if dateTime?
      details = rawActivity?['EventDescription']
      if details? and timestamp?
        activity = {timestamp, location, details}
        activities.push activity
      if !status
        status = @presentStatus rawActivity?['Status']
    {activities, status}

  getEta: (shipment) ->
    eta =  @getArticle(shipment)?['ExpectedDeliveryDate']
    return unless eta?.length
    eta = "#{eta} 00:00 +00:00"
    moment(eta, 'YYYY/MM/DD HH:mm ZZ').toDate()

  getService: (shipment) ->
    @getArticle(shipment)['ProductName']
    
  getWeight: (shipment) ->

  getDestination: (shipment) ->
    @getArticle(shipment)?['DestinationCountry']
    
  requestOptions: ({trackingNumber}) ->
    method: 'GET'
    uri: "https://digitalapi.auspost.com.au/track/v3/search?q=#{trackingNumber}"


module.exports = {AusPostClient}
