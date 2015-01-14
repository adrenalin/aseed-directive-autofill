// Generated by CoffeeScript 1.8.0
(function() {
  define(['module', 'angular'], function(module, angular) {
    var css, directive, path;
    path = module.uri.replace(/[^\/]+$/, '');
    if (!document.getElementById('aseedAutofillCSS')) {
      css = document.createElement('link');
      css.rel = 'stylesheet';
      css.type = 'media/css';
      css.href = "" + path + "autofill.css";
      css.id = 'aseedAutofillCSS';
      document.getElementsByTagName('head')[0].appendChild(css);
    }
    return directive = function($http, $timeout, $q) {
      return {
        templateUrl: "" + path + "autofill.html",
        restrict: 'EA',
        transclude: true,
        scope: {
          subset: '=',
          model: '=',
          bindModel: '=ngModel',
          callback: '=',
          value: '=',
          filter: '=',
          url: '@',
          urlParam: '@',
          label: '@',
          show: '@',
          match: '@',
          placeholder: '@'
        },
        link: function($scope, el, attrs) {
          var clearResults, focusOnNextField, match, maxCount, prevSearch, req, returnItem, search, selectedIndex, selectedItem, setSelectedItem, timer, updater;
          selectedIndex = -1;
          selectedItem = null;
          maxCount = 20;
          match = '';
          if (typeof $scope.show !== 'undefined') {
            maxCount = Number($scope.show);
          }
          if (!maxCount) {
            maxCount = 10;
          }
          if (typeof $scope.match !== 'undefined' && $scope.match) {
            match = $scope.match;
          }
          $scope.results = [];
          $scope.getLabel = function() {
            var i, k, obj, prop, _i, _ref;
            if (typeof this.result === 'string') {
              return this.result;
            }
            if (typeof $scope.label !== 'undefined' && $scope.label) {
              if (typeof this.result[$scope.label] === 'function') {
                return this.result[$scope.label]();
              }
              return this.result[$scope.label];
            }
            prop = ['title', 'name', 'label'];
            if (typeof $scope.model) {
              obj = new $scope.model(this.result);
            } else {
              obj = this.result;
            }
            if (!obj) {
              return '';
            }
            if (typeof obj === 'string') {
              return obj;
            }
            if (typeof obj.getLabel === 'function') {
              return obj.getLabel();
            }
            for (i = _i = 0, _ref = prop.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
              k = prop[i];
              if (typeof obj[k] !== 'undefined') {
                return obj[k].toString();
              }
            }
            return obj.toString();
          };
          prevSearch = '';
          timer = null;
          req = null;
          clearResults = function(populate) {
            if (populate == null) {
              populate = '';
            }
            $scope.results = [];
            if (typeof populate !== 'undefined') {
              $scope.search = populate;
            } else {
              $scope.search = '';
            }
            prevSearch = '';
            timer = null;
            req = null;
            selectedIndex = -1;
            selectedItem = null;
            return el.find('input')[0].blur();
          };
          returnItem = function(item) {
            var o;
            o = item;
            if (typeof $scope.model !== 'undefined') {
              item = new $scope.model(item);
            }
            if (typeof $scope.ngModel !== 'undefined') {
              $scope.ngModel = item;
            }
            if (typeof $scope.bindModel !== 'undefined') {
              $scope.bindModel = item;
            }
            if (typeof $scope.callback !== 'undefined') {
              $scope.callback(item, o);
            }
            return clearResults();
          };
          search = function() {
            var fn;
            if (timer) {
              $timeout.cancel(timer);
            }
            fn = function() {
              var i, item, k, regexp, term, url, v, _i, _ref;
              term = String($scope.search).replace(/^\s+/, '').replace(/\s+$/, '');
              if (term === prevSearch) {
                return;
              }
              if (!term) {
                clearResults();
                return;
              }
              prevSearch = term;
              if (typeof $scope.filter !== 'undefined') {
                $scope.results = $scope.filter(term, $scope.subset);
                return;
              }
              $scope.results = [];
              if (typeof $scope.subset !== 'undefined' && angular.isArray($scope.subset)) {
                regexp = new RegExp("" + match + term, 'i');
                for (i = _i = 0, _ref = $scope.subset.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
                  item = $scope.subset[i];
                  if (typeof item === 'string') {
                    if (item.match(regexp)) {
                      $scope.results.push(item);
                    }
                  } else {
                    for (k in item) {
                      v = item[k];
                      if (typeof v === 'object' || typeof v === 'function') {
                        continue;
                      }
                      if (v.toString().match(regexp)) {
                        $scope.results.push(item);
                        break;
                      }
                    }
                  }
                  if ($scope.results.length > maxCount) {
                    return;
                  }
                }
                return;
              }
              if (typeof $scope.url !== 'undefined') {
                url = $scope.url;
                if (typeof $scope.urlParam !== 'undefined') {
                  if (url.match(/\?/)) {
                    url += "&" + $scope.urlParam + "=";
                  } else {
                    url += "?" + $scope.urlParam + "=";
                  }
                }
                url += term;
                req = $http.get(url);
                return req.success(function(data, status, headers) {
                  var _j, _ref1, _results;
                  _results = [];
                  for (i = _j = 0, _ref1 = data.length; 0 <= _ref1 ? _j < _ref1 : _j > _ref1; i = 0 <= _ref1 ? ++_j : --_j) {
                    _results.push($scope.results.push(data[i]));
                  }
                  return _results;
                });
              }
            };
            return timer = $timeout(fn, 500);
          };
          focusOnNextField = function(d, level) {
            var i, inputs, wrapper;
            if (level == null) {
              level = 0;
            }
            console.log(d);
            if (d.localName === 'form' || level > 10) {
              console.log('prevent too deep DOM searches');
              return;
            }
            if (!d.length) {
              console.log('no parents found');
              return;
            }
            console.log('search level', level);
            wrapper = d.next();
            i = 0;
            while (wrapper && wrapper.length && i < 100) {
              inputs = wrapper.find('input, select, textarea');
              console.log(wrapper, level, i, inputs.length);
              console.log(wrapper.toString());
              if (inputs.length) {
                inputs.get(0).trigger('focus');
                return;
              }
              i++;
              wrapper = wrapper.next();
            }
            return focusOnNextField(d.parent(), level + 1);
          };
          $scope.keydown = function(e) {
            switch (e.keyCode) {
              case 9:
                if (selectedItem) {
                  returnItem(selectedItem);
                  focusOnNextField(el);
                  return true;
                } else {
                  selectedIndex++;
                }
                break;
              case 13:
                if (selectedItem) {
                  returnItem(selectedItem);
                }
                e.preventDefault();
                return false;
              case 27:
                clearResults();
                return true;
              case 38:
                selectedIndex--;
                break;
              case 40:
                selectedIndex++;
                break;
              default:
                search();
                return true;
            }
            setSelectedItem();
            return e.preventDefault();
          };
          updater = function() {
            if (typeof $scope.bindModel === 'undefined') {
              return;
            }
            if ($scope.bindModel && typeof $scope.bindModel.getLabel !== 'undefined') {
              $scope.search = $scope.bindModel.getLabel();
              return;
            }
            if (typeof $scope.bindModel === 'string') {
              $scope.search = $scope.bindModel;
            }
          };
          $scope.$watch('bindModel', updater, true);
          el.find('input').on('blur', function(e) {
            var fn;
            $scope.results = [];
            updater();
            if (!$(this).val()) {
              clearResults();
              fn = function() {
                if (typeof $scope.callback === 'function') {
                  return $scope.callback(null, null);
                } else {
                  return $scope.bindModel = null;
                }
              };
              return $timeout(fn, 50);
            }
          });
          $scope.selectItem = function() {
            returnItem(this.result);
            return clearResults();
          };
          setSelectedItem = function() {
            var minValue;
            minValue = 0;
            if (selectedIndex < minValue) {
              selectedIndex = $scope.results.length - 1;
            }
            if (selectedIndex >= $scope.results.length) {
              selectedIndex = minValue;
            }
            return selectedItem = $scope.results[selectedIndex];
          };
          return $scope.isSelected = function() {
            return this.result === selectedItem;
          };
        }
      };
    };
  });

}).call(this);

//# sourceMappingURL=autofill.js.map
