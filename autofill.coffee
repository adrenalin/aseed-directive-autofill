define ['module', 'angular'], (module, angular) ->
  path = module.uri.replace(/[^\/]+$/, '')
  
  # Load CSS
  unless document.getElementById('aseedAutofillCSS')
    css = document.createElement('link')
    css.rel = 'stylesheet'
    css.type = 'media/css'
    css.href = "#{path}autofill.css"
    css.id = 'aseedAutofillCSS'
    document.getElementsByTagName('head')[0].appendChild css
  
  directive = ($http, $timeout) ->
      templateUrl: "#{path}autofill.html"
      restrict: 'EA'
      scope:
        # Readily loaded subset of items
        subset: '='
        
        # Model class
        model: '='
        
        # Callback for selected result
        callback: '='
        
        # Filter function
        filter: '='
        
        # URL for fetching the results
        url: '@'
        
        # Label property
        label: '@'
        
        # Maximum amount of items displayed
        show: '@'
      
      link: ($scope, el, attrs) ->
        selectedIndex = -1
        selectedItem = null
        
        maxCount = 10
        
        if typeof $scope.show isnt 'undefined'
          maxCount = Number($scope.show)
        
        # Bulletproofing against NaN
        if !maxCount then maxCount = 10
        
        $scope.results = []
        
        # Get human readable label for a result item
        $scope.getLabel = ->
          if typeof $scope.label isnt 'undefined' and $scope.label
            return @result[$scope.label]
          
          # Use heuristics for generating a label
          prop = [
            'title'
            'name',
            'label'
          ]
          
          # If there is a model object, convert to such
          if typeof $scope.model
            obj = new $scope.model(@result)
          else
            obj = @result
          
          # 
          if typeof obj is 'string'
            return obj
          
          if typeof obj.getLabel is 'function'
            return obj.getLabel()
          
          # Try against commonly used label names
          for i in [0...prop.length]
            k = prop[i]
            if typeof obj[k] isnt 'undefined'
              return obj[k].toString()
          
          # When the heuristics fail, pass the object as a string
          return obj.toString()
        
        # Clear result set
        clearResults = ->
          $scope.results = []
          $scope.search = ''
          prevSearch = ''
          timer = null
          req = null
          selectedIndex = -1
          selectedItem = null
        
        # Return the selected item to the controller
        returnItem = (item) ->
          o = item
          if typeof $scope.model isnt 'undefined'
            item = new $scope.model(item)
          
          if typeof $scope.ngModel isnt 'undefined'
            $scope.ngModel = item
          
          if typeof $scope.callback isnt 'undefined'
            $scope.callback(item, o)
          
          # Clear results
          clearResults()
        
        prevSearch = ''
        timer = null
        req = null
        
        # Search for results
        search = ->
          if timer
            $timeout.cancel(timer)
          
          # Timed trigger so that the search isn't 
          fn = ->
            term = String($scope.search).replace(/^\s+/, '').replace(/\s+$/, '')
            
            if term is prevSearch
              return
            
            if !term
              clearResults()
              return
            
            prevSearch = term
            
            if typeof $scope.filter isnt 'undefined'
              $scope.results = $scope.filter(term, $scope.subset)
              return
            
            $scope.results = []
            
            # Filter from a subset
            if typeof $scope.subset isnt 'undefined' and angular.isArray $scope.subset
              regexp = new RegExp(term, 'i')
              
              # Do a one level iteration
              for i in [0...$scope.subset.length]
                item = $scope.subset[i]
                
                if typeof item is 'string'
                  if item.match(regexp)
                    $scope.results.push item
                else
                  for k, v of item
                    if typeof v is 'object' or typeof v is 'function'
                      continue
                    if v.toString().match(regexp)
                      $scope.results.push item
                
                if $scope.results.length > maxCount then return
              
              return
          
            # @TODO: search over HTTP
          
          timer = $timeout fn, 100
        
        # Receive keyboard events from the search field
        $scope.keydown = (e) ->
          switch e.keyCode
            when 13
              if selectedItem
                returnItem(selectedItem)
              return true
            
            when 27
              clearResults()
              el.find('input')[0].blur()
              return true
            
            when 38
              selectedIndex--
            
            when 40
              selectedIndex++
            
            else
              search()
              return true
          
          setSelectedItem()
          e.preventDefault()
        
        # Select an item by clicking on it
        $scope.selectItem = ->
          returnItem @result
          clearResults()
        
        # Select an item on the GUI
        setSelectedItem = ->
          # Keep to bounds, allow rotating
          minValue = 0
          if selectedIndex < minValue then selectedIndex = $scope.results.length - 1
          if selectedIndex >= $scope.results.length then selectedIndex = minValue
          selectedItem = $scope.results[selectedIndex]
        
        # 
        $scope.isSelected = ->
          return (@result is selectedItem)
