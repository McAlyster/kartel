exports.config =
        plugins:
                sass:
                        mode: 'native'
                        options:
                                includePaths: ["bower_components/compass-mixins/lib/"]

        conventions:
                assets: /^app\/assets\//
        modules:
                definition: false
                wrapper: false
        paths:
            public: '_public'
        files:
                javascripts:
                        joinTo:
                                'js/vendor.js': [
                                        /^bower_components/
                                        /^vendor\/scripts/
                                ]
                                'js/app.js': [
                                        'app/scripts/*.coffee'
                                        'app/scripts/candidature/*.coffee'
                                        'app/scripts/common/**/*.coffee'
                                        'app/scripts/*.js'
                                ]
                         order:
                                before: [
                                        'bower_components/jquery/dist/jquery.js'
                                        'bower_components/angular/angular.js'
                                        'bower_components/angularui/angular-ui.js'
                                        'bower_component/angularui/angular-ui-ieshiv.js'

                                        'bower_components/codemirror/lib/codemirror.js'
                                        'bower_components/codemirror/mode/css/css.js'
                                ]
                                after: [

                                ]
                stylesheets:
                        joinTo:
                                'css/vendor.css': [
                                        /^bower_components/
                                        /^vendor\/styles/
                                ]
                                'css/app.css': /^app\/styles/
                        order:
                                after: [

                                ]
