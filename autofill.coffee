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
  
  directive = ($http, $timeout, $q) ->
    templateUrl: "#{path}autofill.html"
    restrict: 'EA'
    transclude: true
    scope:
      # Readily loaded subset of items
      subset: '='
      
      # Model class
      model: '='
      
      # Bind model
      bindModel: '=ngModel'
      
      # Callback for selected result
      callback: '='
      
      # Field value
      value: '='
      
      # Filter function
      filter: '='
      
      # URL for fetching the results
      url: '@'
      
      # URL parameter
      urlParam: '@'
      
      # Label property
      label: '@'
      
      # Maximum amount of items displayed
      show: '@'
      
      # Position of matcing, either empty or '^' to mark the beginning of the string
      match: '@'
      
      # Placeholder attribute
      placeholder: '@'
    
    link: ($scope, el, attrs) ->
      selectedIndex = -1
      selectedItem = null
      
      maxCount = 20
      match = ''
      
      if typeof $scope.show isnt 'undefined'
        maxCount = Number($scope.show)
      
      # Bulletproofing against NaN
      if !maxCount then maxCount = 10
      
      # Regexp matcher
      if typeof $scope.match isnt 'undefined' and $scope.match
        match = $scope.match
      
      $scope.results = []
      
      # Get human readable label for a result item
      $scope.getLabel = ->
        if typeof @result is 'string' then return @result
        
        if typeof $scope.label isnt 'undefined' and $scope.label
          if typeof @result[$scope.label] is 'function'
            return @result[$scope.label]()
          
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
        
        if !obj
          return ''
        
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
      prevSearch = ''
      timer = null
      req = null
      clearResults = (populate = '') ->
        $scope.results = []
        
        if typeof populate isnt 'undefined'
          $scope.search = populate
        else
          $scope.search = ''
        
        prevSearch = ''
        timer = null
        req = null
        selectedIndex = -1
        selectedItem = null
        el.find('input')[0].blur()
      
      # Return the selected item to the controller
      returnItem = (item) ->
        o = item
        if typeof $scope.model isnt 'undefined'
          item = new $scope.model(item)
        
        if typeof $scope.ngModel isnt 'undefined'
          $scope.ngModel = item
        
        if typeof $scope.bindModel isnt 'undefined'
          $scope.bindModel = item
        
        if typeof $scope.callback isnt 'undefined'
          $scope.callback(item, o)
        
        # Clear results
        clearResults()
      
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
            regexp = new RegExp("#{match}#{term}", 'i')
            
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
                    break
              
              if $scope.results.length > maxCount then return
            
            return
        
          # Search over HTTP
          if typeof $scope.url isnt 'undefined'
            url = $scope.url
            
            if typeof $scope.urlParam isnt 'undefined'
              if url.match(/\?/) then url += "&#{$scope.urlParam}=" else url += "?#{$scope.urlParam}="
            url += term
            req = $http.get url
            req.success (data, status, headers) ->
              for i in [0...data.length]
                $scope.results.push data[i]
              
        timer = $timeout fn, 500
      
      focusOnNextField = (d, level = 0) ->
        console.log d
        if d.localName is 'form' or level > 10
          console.log 'prevent too deep DOM searches'
          return
        
        unless d.length
          console.log 'no parents found'
          return
        
        console.log 'search level', level
        
        wrapper = d.next()
        
        i = 0
        
        while wrapper and wrapper.length and i < 100
          inputs = wrapper.find('input, select, textarea')
          console.log wrapper, level, i, inputs.length
          console.log wrapper.toString()
          
          if inputs.length
            inputs.get(0).trigger('focus')
            return
          i++
          wrapper = wrapper.next()
        
        focusOnNextField(d.parent(), level + 1)
      
      # Receive keyboard events from the search field
      $scope.keydown = (e) ->
        switch e.keyCode
          when 9
            if selectedItem
              returnItem(selectedItem)
              
              # Focus on the next form field
              focusOnNextField(el)
              return true
            else
              selectedIndex++
          
          when 13
            if selectedItem
              returnItem(selectedItem)
            e.preventDefault()
            return false
          
          when 27
            clearResults()
            return true
          
          when 38
            selectedIndex--
          
          when 40
            selectedIndex++
          
          else
            #console.log e.keyCode
            search()
            return true
        
        setSelectedItem()
        e.preventDefault()
      
      updater = ->
        return if typeof $scope.bindModel is 'undefined'
        
        if $scope.bindModel and typeof $scope.bindModel.getLabel isnt 'undefined'
          $scope.search = $scope.bindModel.getLabel()
          return
        
        if typeof $scope.bindModel is 'string'
          $scope.search = $scope.bindModel
          return
      
      $scope.$watch 'bindModel', updater, true
      #$scope.$watch 'search', updater, true
      
      el.find('input').on 'blur', (e) ->
        $scope.results = []
        updater()
        
        unless $(this).val()
          clearResults()
          
          fn = ->
            if typeof $scope.callback is 'function'
              $scope.callback(null, null)
            else
              $scope.bindModel = null
          $timeout fn, 50
      
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