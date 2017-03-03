angular.module('memoire.services', ['restangular'])

# Services
.factory('RestangularV2', (Restangular) ->
        return Restangular.withConfig((RestangularConfigurer) ->
            RestangularConfigurer.setBaseUrl(config.rest_uri_v2)
        )
)

.factory('Users', (RestangularV2) ->
        return RestangularV2.withConfig((RestangularConfigurer) ->
        ).service('people/user')
)

.factory('Registration', (Restangular) ->
        # pas besoin d'un token - on le laisse en V1
        return Restangular.withConfig((RestangularConfigurer) ->
              RestangularConfigurer.setBaseUrl(config.rest_uri_v2)
        ).service('people/user/register')
)

.factory('RestAuth', (RestangularV2) ->
        return RestangularV2.withConfig((RestangularConfigurer) ->
        ).service('rest-auth')
)

.factory('Artists', (Restangular) ->
        return Restangular.service('people/artist')
)

.factory('ArtistsV2', (RestangularV2) ->
        return RestangularV2.withConfig((RestangularConfigurer) ->

        ).service('people/artist')
)

.factory('Candidatures', (RestangularV2) ->
        return RestangularV2.withConfig((RestangularConfigurer) ->

        ).service('school/student-application')
)

.factory('Students', (Restangular) ->
        return Restangular.service('school/student')
)

.factory('Promotions', (Restangular) ->
        return Restangular.service('school/promotion')
)

.factory('Artworks', (Restangular) ->
        return Restangular.service('production/artwork')
)

.factory('Events', (Restangular) ->
        return Restangular.service('production/event')
)

.factory('Collaborators', (Restangular) ->
        return Restangular.service('production/productionstafftask/')
)

.factory('Galleries', (RestangularV2) ->
        return RestangularV2.withConfig((RestangularConfigurer) ->
        ).service('assets/gallery')
)

.factory('Media', (RestangularV2) ->
        return RestangularV2.withConfig((RestangularConfigurer) ->
        ).service('assets/medium')
)

.factory('Partners', (Restangular) ->
        return Restangular.service('production/productionorganizationtask/')
)

.factory('Authentification', (RestangularV2) ->
        return RestangularV2.withConfig((RestangularConfigurer) ->
        ).service('rest-auth')
)

.factory('Login', (RestangularV2) ->
        return RestangularV2.withConfig((RestangularConfigurer) ->
        ).service('rest-auth/login/')
)
.factory('Logout', (RestangularV2) ->
        return RestangularV2.withConfig((RestangularConfigurer) ->
        ).service('rest-auth/logout/')
)


# AME Service
.factory('AmeRestangular', (Restangular) ->
      return Restangular.withConfig((RestangularConfigurer) ->
            RestangularConfigurer.setBaseUrl(config.ame_rest_uri);
            RestangularConfigurer.setDefaultRequestParams({key: config.ame_key});
            RestangularConfigurer.setDefaultHeaders({'Content-Type': 'charset=UTF-8'})
      )
)
