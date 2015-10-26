require_relative 'controller'
require_relative 'router'

module RackStep

  class App

    # We will store the request and create a router in this class initializer.
    attr_reader :request, :router

    # Settings is a hash that will be injected into the controller. This hash
    # may contain "global" settings, like a connection to database, and other
    # things that should be initiaized only once while the app is starting.
    attr_accessor :settings

    # Static method called from config.ru ("run App").
    def self.call(env)
      new(env).process_request
    end

    def initialize(env)
      @request = Rack::Request.new(env)
      @router = RackStep::Router.new
      @settings = Hash.new

      # Adding default routes to handle page not found (404).
      for_all_verbs_add_route('notfound', 'RackStep::ErrorController', 'not_found')
    end

    def process_request
      verb = request.request_method
      path = request.path

      # In RackStep, each request is processed by a method of a controller. The
      # router is responsable to find, based on the given path and http verb,
      # the apropriate controller and method to handle the request.
      route = router.find_route_for(path, verb)
      # Initialize the correspondent controller.
      controller = Object.const_get(route.controller).new
      # Inject the request into the controller.
      controller.request = request
      # Inject the settings into the controller.
      controller.settings = settings
      # Execute the before method of this controller.
      controller.send(:before)
      # Execute the apropriate method/action.
      controller.send(route.method)
      # Get from the controller what is the response for this request.
      response = controller.response
      # Adding the content type to the header (other things may have been
      # inserted by the user).
      response[:headers]['Content-Type'] = response[:type]
      # Generate a rack response that will be returned to the user.
      rackResponse = Rack::Response.new( response[:content],
                          response[:httpStatus],
                          response[:headers] )
                        #  { 'Content-Type' => response[:type],
                        #    'WWW-Authenticate' => 'Basic realm="Restricted Area"' } )
    end

    # Adds new routes to the application, one for each possible http verb (GET,
    # POST, DELETE and PUT).
    def for_all_verbs_add_route(path, controller, method)
      @router.add_route('GET', path, controller, method)
      @router.add_route('POST', path, controller, method)
      @router.add_route('DELETE', path, controller, method)
      @router.add_route('PUT', path, controller, method)
    end

    # Adds a new route to the application.
    def add_route(verb, path, controller, method)
      @router.add_route(verb, path, controller, method)
    end

  end

end