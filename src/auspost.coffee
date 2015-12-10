{reduce} = require 'underscore'
moment = require 'moment-timezone'
{titleCase} = require 'change-case'
{ShipperClient} = require './shipper'

class AusPostClient extends ShipperClient

  constructor: (@options) ->
    super

  validateResponse: (response, cb) ->
    response = JSON.parse response
    return cb(error: 'no tracking info found') unless response?.length
    response = response[0]
    return cb(error: 'missing events') unless response['TrackingResults']?
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
    codeStr = eventType.match('EVENT_(.*)$')?[1]
    return unless codeStr?.length
    eventCode = parseInt codeStr
    return if isNaN eventCode
    status = STATUS_MAP[eventCode]
    return status if status?
    return ShipperClient.STATUS_TYPES.EN_ROUTE if (eventCode < 300 and eventCode > 101)

  getActivitiesAndStatus: (shipment) ->
    activities = []
    status = null
    rawActivities = shipment?['TrackingResults']
    for rawActivity in rawActivities or []
      location = @presentAddress 'EL', rawActivity
      dateTime = "#{rawActivity?['serverDate']} #{rawActivity?['serverTime']}"
      timestamp = moment("#{dateTime} +00:00").toDate()
      details = rawActivity?['EventCodeDesc']
      if details? and timestamp?
        activity = {timestamp, location, details}
        activities.push activity
      if !status
        status = @presentStatus rawActivity?['EventCode']
    {activities, status}

  getEta: (shipment) ->
    eta = shipment?['TrackingResults']?[0]?['EstimatedDeliveryDate']
    return unless eta?.length
    eta = "#{eta} 00:00 +00:00"
    moment(eta, 'MM/DD/YYYY HH:mm ZZ').toDate()

  getService: (shipment) ->

  getWeight: (shipment) ->
    return unless shipment?['Pieces']?.length
    piece = shipment['Pieces'][0]
    weight = "#{piece['Weight']}"
    units = piece['WeightUnit']
    weight = "#{weight} #{units}" if units?
    weight

  getDestination: (shipment) ->
    @presentAddress 'PD', shipment?['TrackingResults']?[0]

  requestOptions: ({trackingNumber}) ->
    method: 'GET'
    uri: "https://digitalapi-ptest.npe.auspost.com.au/track/v3/search?q=#{trackingNumber}"


module.exports = {AusPostClient}
