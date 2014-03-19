define [
  'jquery',
  'underscore',
  'backbone',
  'globals',
  'cs!views/app'
], ($, _, Backbone, globals, AppView, SessionView) ->

  Router = Backbone.Router.extend
    routes:
      'session': 'showSession',
      'login': 'showLogin',
      # '*actions': 'defaultAction'

    initialize: ->
      @appView = new AppView()

    showLogin: () ->
      require ['cs!views/login'], (LoginView) =>
        globals.router.navigate "/login", {replace: true}
        @loginView ?= new LoginView()
        @appView.render(@loginView)

    showSession: () ->
      require ['cs!views/session'], (SessionView) =>
        globals.router.navigate "/session", {replace: true}
        @sessionView ?= new SessionView()
        @appView.render(@sessionView)

  Router
