_ = require("lodash")
redis = require("redis")

config = require("../config")
Logger = require("./logger")
Utils = require("./utils")

moduleDeps = ["RedisAction"]

# A module that publishes messages to redis.
module.exports = class RedisPublisher

  constructor: ->
    config.modules.wait moduleDeps, =>
      @redisAction = config.modules.get("RedisAction")
      @pub = redis.createClient()

  # Publish list of shapes to appropriate clients
  #
  # @param meetingID [string] the ID of the meeting
  # @param sessionID [string] the ID of the user, if `null` will send to all clients
  # @param callback(err, succeeded) [Function] callback to call when finished
  publishShapes: (meetingID, sessionID, callback) ->
    shapes = []
    @redisAction.getCurrentPresentationID meetingID, (err, presentationID) =>
      @redisAction.getCurrentPageID meetingID, presentationID, (err, pageID) =>
        @redisAction.getItems meetingID, presentationID, pageID, "currentshapes", (err, shapes) =>

          receivers = (if sessionID? then sessionID else meetingID)
          @pub.publish receivers, JSON.stringify(["all_shapes", shapes])
          callback?(null)

  # Publish load users to appropriate clients.
  #
  # @param meetingID [string] the ID of the meeting
  # @param sessionID [string] the ID of the user, if `null` will send to all clients
  # @param callback(err, succeeded) [Function] callback to call when finished
  publishLoadUsers: (meetingID, sessionID, callback) ->
    usernames = []
    @redisAction.getUsers meetingID, (err, users) =>
      users.forEach (user) =>
        usernames.push
          name: user.username
          id: user.pubID

      receivers = (if sessionID? then sessionID else meetingID)
      @pub.publish "bigbluebutton:bridge", JSON.stringify([receivers, "load users", usernames])
      callback?(null, true)

  # Publish the current presenter's public ID to appropriate clients.
  #
  # @param meetingID [string] the ID of the meeting
  # @param sessionID [string] the ID of the user, if `null` will send to all clients
  # @param callback(err, succeeded) [Function] callback to call when finished
  publishPresenter: (meetingID, sessionID, callback) ->
    @redisAction.getPresenterPublicID meetingID, (err, publicID) =>
      receivers = (if sessionID? then sessionID else meetingID)
      @pub.publish receivers, JSON.stringify(["setPresenter", publicID])
      callback?(null, true)

  # Publishes a user join.
  #
  # @param meetingID [string] the ID of the meeting
  # @param sessionID [string] the ID of the user, if `null` will send to all clients
  # @param callback(err, succeeded) [Function] callback to call when finished
  publishUserJoin: (meetingID, sessionID, userid, username, callback) ->
    receivers = (if sessionID? then sessionID else meetingID)
    @pub.publish "bigbluebutton:bridge", JSON.stringify([receivers, "user join", userid, username, "VIEWER"])
    callback?(null, true)

  # Get all chat messages from redis and publish to the appropriate clients
  #
  # @param meetingID [string] the ID of the meeting
  # @param sessionID [string] the ID of the user, if `null` will send to all clients
  # @param callback(err, succeeded) [Function] callback to call when finished
  # @todo callback should be called at the end and only once, can use async for this
  publishMessages: (meetingID, sessionID, callback) ->
    messages = []
    @redisAction.getCurrentPresentationID meetingID, (err, presentationID) =>
      @redisAction.getCurrentPageID meetingID, presentationID, (err, pageID) =>
        @redisAction.getItems meetingID, presentationID, pageID, "messages", (err, messages) =>
          receivers = (if sessionID? then sessionID else meetingID)
          @pub.publish receivers, JSON.stringify(["all_messages", messages])
          callback?(true)

  # Publish list of slides from redis to the appropriate clients
  #
  # @param meetingID [string] the ID of the meeting
  # @param sessionID [string] the ID of the user, if `null` will send to all clients
  # @param callback(err, succeeded) [Function] callback to call when finished
  # @todo callback should be called at the end and only once, can use async for this
  publishSlides: (meetingID, sessionID, callback) ->
    slides = []
    @redisAction.getCurrentPresentationID meetingID, (err, presentationID) =>
      @redisAction.getPageIDs meetingID, presentationID, (err, pageIDs) =>
        slideCount = 0
        pageIDs.forEach (pageID) =>
          @redisAction.getPageImage meetingID, presentationID, pageID, (err, filename) =>
            @redisAction.getImageSize meetingID, presentationID, pageID, (err, width, height) =>
              path = config.presentationImagePath(meetingID, presentationID, filename)
              slides.push [path, width, height]
              if slides.length is pageIDs.length
                receivers = (if sessionID? then sessionID else meetingID)
                @pub.publish receivers, JSON.stringify(["all_slides", slides])
                callback?(true)

  # When the list of slides is loaded, we usually have to update the current image
  # being show. This method can be use to do it.
  #
  # @param meetingID [string] the ID of the meeting
  # @param sessionID [string] the ID of the user, if `null` will send to all clients
  # @param callback(err, succeeded) [Function] callback to call when finished
  publishCurrentImagePath: (meetingID, sessionID, callback) ->
    @redisAction.getPathToCurrentImage meetingID, (err, path) =>
      receivers = (if sessionID? then sessionID else meetingID)
      @pub.publish receivers, JSON.stringify(["changeslide", path])
      callback?(null, true)

  # Publishes the current tool.
  #
  # @param meetingID [string] the ID of the meeting
  # @param sessionID [string] the ID of the user, if `null` will send to all clients
  # @param callback(err, succeeded) [Function] callback to call when finished
  publishTool: (meetingID, sessionID, callback) ->
    @redisAction.getCurrentTool meetingID, (err, tool) =>
      receivers = (if sessionID? then sessionID else meetingID)
      @pub.publish receivers, JSON.stringify(["toolChanged", tool])
      callback?(null, true)

  # Publishes a viewbox message.
  #
  # @param meetingID [string] the ID of the meeting
  # @param sessionID [string] the ID of the user, if `null` will send to all clients
  # @param callback(err, succeeded) [Function] callback to call when finished
  publishViewBox: (meetingID, sessionID, callback) ->
    @redisAction.getCurrentPresentationID meetingID, (err, presentationID) =>
      @redisAction.getViewBox meetingID, (err, viewBox) =>
        receivers = (if sessionID? then sessionID else meetingID)
        @pub.publish receivers, JSON.stringify(["paper", viewBox[0], viewBox[1], viewBox[2], viewBox[3]])
        callback?(null, true)

  # Publishes a user leave message.
  #
  # @param meetingID [string] the ID of the meeting
  # @param sessionID [string] the ID of the user, if `null` will send to all clients
  # @param pubID [string] the public ID of the user
  # @param callback(err, succeeded) [Function] callback to call when finished
  publishUserLeave: (meetingID, sessionID, pubID, callback) ->
    receivers = (if sessionID? then sessionID else meetingID)
    @pub.publish "bigbluebutton:bridge", JSON.stringify([receivers, "user leave", pubID])
    callback?(null, true)

  # Publishes a user list change to the appropriate clients.
  #
  # @param meetingID [string] the ID of the meeting
  # @param sessionID [string] the ID of the user, if `null` will send to all clients
  # @param callback(err, succeeded) [Function] callback to call when finished
  # @todo review if we really need this method
  publishUsernames: (meetingID, sessionID, callback) ->
    usernames = []
    # @TODO: @_getUsers doesn't exist, probably this method is never being called
    # @_getUsers meetingID, (users) =>
    #   users.forEach (user) =>
    #     usernames.push
    #       name: user.username
    #       id: user.pubID

    #   receivers = (if sessionID? then sessionID else meetingID)
    #   @pub.publish "bigbluebutton:bridge", JSON.stringify([receivers, "user list change", usernames])
    callback?(null, true)

  # Publishes a chat message informing that a text message is too long.
  #
  # @param meetingID [string] the ID of the meeting
  # @param sessionID [string] the ID of the user, if `null` will send to all clients
  # @param callback(err, succeeded) [Function] callback to call when finished
  publishChatMessageTooLong: (meetingID, sessionID, callback) ->
    receivers = (if sessionID? then sessionID else meetingID)
    @pub.publish receivers, JSON.stringify(["msg", "System", "Message too long."])
    callback?(null, true)

  # Publishes a chat message.
  #
  # @param meetingID [string] the ID of the meeting
  # @param username [string] the username of the user that sent the message
  # @param msg [string] the text message
  # @param pubID [string] the public ID of the user sending the message
  # @param callback(err, succeeded) [Function] callback to call when finished
  publishChatMessage: (meetingID, username, msg, pubID, callback) ->
    @pub.publish "bigbluebutton:bridge", JSON.stringify([meetingID, "msg", username, msg, pubID])
    callback?(null, true)

  # Publishes a logout message to a user.
  #
  # @param sessionID [string] the ID of the user
  # @param callback(err, succeeded) [Function] callback to call when finished
  publishLogout: (sessionID, callback) ->
    @pub.publish sessionID, JSON.stringify(["logout"])
    callback?(null, true)
