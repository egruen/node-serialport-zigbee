#<author>Eduard Gruen</author>
#<email>eduard.gruen@greenux.de</email>
#<date>2012-03-13</date>
#<version>1.0</version>
#<summary>zigbee.coffe is capable of all zigbee needed commands
#and defines the parser needed for the serialport-module</summary>

#loading of the required node-modules
class ZigBee
  constructor: (@serialPort) ->

  #send a AT-Command and get prompts or errors back
  sendCommand : (mesg, callback) ->
    selfPort =  @serialPort
    @serialPort.write( mesg + "\r")
    @serialPort.on(mesg, (data) ->
      err = data[1]
      if err isnt "OK" or "" or null
        return callback(err, "")
    )
    @serialPort.on(mesg.substr( mesg.indexOf("+")), (data) ->
      return callback(null, data))
    @serialPort.once("SEQ", (data) ->
      self = @
      selfPort.once("ACK", (ackData) ->
        if (ackData.split(":"))[1] is (data)
          return
        )
      selfPort.once("NACK", (nackData) ->
        if (nackData.split(":"))[1] is (data.split(":"))[1]
          return selfPort.write(mesg + "\r")
        )
      return
    )

  #to identify a remote member, address needed
  identify : (adrs, callback) ->
    @.sendCommand("AT+IDENT:" + adrs, (err) ->
      return callback(err) if err?)

  #get Mac of this node back
  getMac : (callback) ->
    @.sendCommand("ATI", (err) ->)
    @serialPort.on("ATI", (data) ->
      return callback(data[3])
    )

  #scan for PANs
  scanPan : (callback) ->
    @.sendCommand("AT+PANSCAN", (err, data) ->
      return callback(err, data)
    )

  #create a new Network
  createNetwork : (callback) ->
    @.sendCommand("AT+EN", (err, data) ->
      return callback(err, data) if err?)
    @serialPort.on("JPAN", (data) ->
      return callback(null, packet[1])
    )

  #get Nodes of connected network
  getNodes : (callback) ->
    console.log("Checking for new lamps!")
    @sendCommand("AT+SN", (err, data) ->
      return callback(err, "") if err?)
    @serialPort.on("FFD", (data) ->
      return callback(null, data))
    @serialPort.on("MED", (data) ->
      return callback(null, data))
    @serialPort.on("SED", (data) ->
      return callback(null, data))
    @serialPort.on("ZED", (data) ->
      return callback(null, data))
    

  #send an unicast to address with data
  uCast : (address, data, callback) ->
    @.sendCommand("AT+UCAST:" + address + "=" + data, (err, data) ->
      return callback(err) if err?
    )

  #listen on unicasts
  onUcast : (callback) ->
    @serialPort.on("UCAST", (data) ->
      return callback(null, data))

exports.ZigBee = ZigBee

#this is the parser to emit zigbee-defined events
exports.parser = ->
  return (emitter, buffer) ->
    data = (buffer.toString()
      .replace(/\n/g, "")
      .replace(/\r\r/g, "\r")
      .split("\r"))
      .filter( -> return true)
    if data[0]
      command = data[0]
    else
      command = (data[1].split(":"))[0]
      data = data[1]
    emitter.emit(command, data)
