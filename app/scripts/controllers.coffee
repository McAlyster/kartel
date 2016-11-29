# -*- tab-width: 2 -*-
"use strict"

angular.module('memoire.controllers', ['memoire.services'])

.controller('QuickSearch', ($scope, $q, $state, Restangular) ->
  $scope.selected = null

  $scope.goTo = ($item, $model, $label) ->
    # Extract the id
    matches = $item.resource_uri.match(/\d+$/)
    if matches
      id = matches[0]

    if $item.resource_uri.search("production") != -1
      $state.go("artwork-detail", {id: id})

    else if $item.resource_uri.search("student") != -1
      $state.go("school.student", {id: id})


  $scope.search = (value) ->
    artworks = Restangular.all('production/artwork').customGET('search', {q: value}).then((response) ->
      return response.objects
    )

    students = Restangular.all('school/student').customGET('search', {q: value}).then((response) ->
      return response.objects
    )

    $q.all([students, artworks]).then((results) ->
      return _.flatten(_.map(results, _.values))
    )
)

.controller('ArtistListingController', ($scope, Artists, $state) ->
  $scope.letter = $state.params.letter || "a"
  $scope.artists = Artists.getList({user__last_name__istartswith: $scope.letter, limit: 200}).$object
  $scope.alphabet = "abcdefghijklmnopqrstuvwxyz".split("")
)

.controller('ArtworkListingController', ($scope, Artworks, $state) ->
  $scope.letter = $state.params.letter || "a"
  $scope.offset = parseInt($state.params.offset) || 0
  $scope.limit = 200
  $scope.artworks = Artworks.getList({title__istartswith: $scope.letter, limit: $scope.limit, offset:$scope.offset }).$object
  $scope.alphabet = "abcdefghijklmnopqrstuvwxyz".split("")
)

.controller('ArtworkGenreListingController', ($scope, Artworks, $state) ->
  $scope.genre = $state.params.genre || ""
  $scope.artworks = Artworks.getList({genres: $scope.genre, limit: 200}).$object
)


.controller('SchoolController', ($scope, $state, Promotions, Students) ->
  $scope.promotions = []

  Promotions.getList({order_by: "-starting_year"}).then((promotions) ->
    $scope.promotions = promotions
  )

)


.controller('PromotionController', ($scope, $stateParams, Students, Promotions) ->


  $scope.promotion = Promotions.one($stateParams.id).get().$object

  $scope.students = Students.getList({promotion: $stateParams.id, limit: 500}).$object
)

.controller('ArtistController', ($scope, $stateParams, Artists, Artworks) ->
  $scope.student = null
  $scope.artworks = []

  Artists.one().one($stateParams.id).get().then((artist) ->
    $scope.student = artist

    # Fetch artworks
    for artwork_uri in $scope.student.artworks
      matches = artwork_uri.match(/\d+$/)
      if matches
        artwork_id = matches[0]
        Artworks.one(artwork_id).get().then((artwork) ->
          $scope.artworks.push(artwork)
        )
  )
)

.controller('ArtworkController', ($scope, $stateParams, $sce, Lightbox, Artworks, AmeRestangular,  Events, Collaborators, Partners) ->
  $scope.artwork = null
  $scope.events = []


  $scope.main_picture_gallery = {media: []}
  # ame gallery vars for gallery
  $scope.ame_artwork_gallery = {media: []}
  # ame available for template
  $scope.ame_access = true

  Artworks.one().one($stateParams.id).get().then((artwork) ->
    $scope.artwork = artwork
    for event_uri in $scope.artwork.events
      matches = event_uri.match(/\d+$/)
      if matches
        event_id = matches[0]
        Events.one(event_id).get().then((event) ->
          $scope.events.push(event)
        )

    for collaborator_uri,key in $scope.artwork.collaborators
      if typeof collaborator_uri.match == Function
        matches = collaborator_uri.match(/\d+$/)
        if matches
          collaborator_id = matches[0]
          $scope.artwork.collaborators[key] = Collaborators.one(collaborator_id).get().$object


    for partner_uri,key in $scope.artwork.partners
      if typeof partner_uri.match == Function
        matches = partner_uri.match(/\d+$/)
        if matches
          partner_id = matches[0]
          $scope.artwork.partners[key] = Partners.one(partner_id).get().$object



    search = ""
    #return all artwork video and filtre with idFrezsnoy - TODO search idFresnoy in api
    AmeRestangular.all("api_search/").get("",{"search": search, "flvfile": "true", "previewsize":"scr"}).then((ame_artwork) ->
      for archive in ame_artwork
        # valid reference id Fresnoy => id AME

        if parseInt(archive.field201) == $scope.artwork.id

          if archive.flvpath

            $scope.ame_artwork_gallery.media.push({
              picture : archive.flvthumb
              medium_url : $sce.trustAsResourceUrl(archive.flvpath)
              description : archive.field8 #media ame title
           })

    , (response) ->
      #erreur service
      $scope.ame_access = false
    )
    # Fake a gallery for the main visual so we can reuse the gallery
    # component
    $scope.main_picture_gallery.media.push({
      picture: artwork.picture
      description: 'Visuel principal'
    })



  )

)

.controller('StudentController', ($scope, $stateParams, Students, Artworks, Promotions) ->
  $scope.student = null
  $scope.promotion = null
  $scope.artworks = []

  Students.one().one($stateParams.id).get().then((student) ->
    $scope.student = student

    # Fetch promotion
    matches = student.promotion.match(/\d+$/)
    if matches
      promotion_id = matches[0]
      Promotions.one(promotion_id).get().then((promotion) ->
        $scope.promotion = promotion
      )

    # Fetch artworks
    for artwork_uri in $scope.student.artworks
      matches = artwork_uri.match(/\d+$/)
      if matches
        artwork_id = matches[0]
        Artworks.one(artwork_id).get().then((artwork) ->
          $scope.artworks.push(artwork)
        )
  )
)


.controller('CandidatureFormController2', ($rootScope, $stateParams) ->

    console.log(localStorage)

)

.controller('InitCandidatureController', ($rootScope, $scope, $stateParams) ->

    $scope.setLang = (lang) ->
      console.log(lang)


)


# Candidature
.controller('CandidatureBreadCrumbController', ($rootScope, $stateParams) ->

  if not $rootScope.step
    $rootScope.step = []

  $rootScope.step.current = $stateParams.step

  $rootScope.step.next = $rootScope.step.current + 1

  console.log($rootScope.step)

)
# Candidature Form

.controller('CandidatureFormController', (
        $scope, $q, $state, $filter
        Users, Artists, Restangular, Candidatures,
        ISO3166, Upload,
  ) ->

  console.log($scope)

  $scope.application = Candidatures
  $scope.user = Users
  $scope.user.profile = []
  $scope.artist = Artists

  $scope.create = (form) ->



    console.log($scope.user)
    console.log($scope.artist)

    if(!form.$valid)
          console.log("Formulaire incomplet")
          console.log(form)
          return

    # change date after validation
    $scope.user.profile.birthdate = $filter('date')($scope.profile.birthdate, 'yyyy-MM-dd')

    # change other_language
    $scope.user.profile.other_language = $scope.user.profile.other_language.join(",")

    # cursus to txt
    $scope.user.profile.cursus = ""
    for item in $scope.cursus.items
      $scope.user.profile.cursus += item.year+ " - "+
       item.infos+"\r\n"

    Users.post($scope.user).then((recordedUser) ->

      console.log($scope.artist)
      console.log(recordedUser)
      $scope.artist.user = recordedUser.url

      console.log($scope.artist)

      Artists.post($scope.artist).then((recordedArtist) ->

            $scope.application.artist = recordedArtist.url

            Candidatures.post($scope.application).then((candidature) ->
              console.log("ok Candidature")
            )
        )
  )


    #update
  $scope.update = (user, form) ->
    return true


  if(localStorage.id_token)
    #user get
    Users.one(localStorage.user_id).get().then((user) ->

      if(user.username=="getoken")
        user.username = ""

      $scope.user = user


      #user profile get
      if (user.profile)
        matches = user.profile.match(/\d+$/)
        if matches
          profile_id = matches[0]
          Profiles.one(profile_id).get().then((profile) ->
            $scope.profile = profile
        )
        #artist get
      """
      Artists.getList().then((artists) ->
          for artist in artists
              if(parseInt(artist.user.match(/\d+$/)[0]) == $scope.user.id)
                $scope.artist = artist

            if($scope.artist == undefined)
              $scope.artist = Artists

      )"""

    )

  # Birthdate minimum
  current_year = new Date().getFullYear()
  age_min = 18
  age_max = 35
  $scope.birthdateMax = new Date(current_year-age_min,11,31)
  $scope.birthdateMin = new Date(current_year-age_max,11,31)

  #country
  $scope.countries = ISO3166.countryToCode

  #phone patterne
  $scope.phone_pattern = /^\+?\d{2}[-. ]?\d{9}$/

  #upload file
  $scope.upload_percentage = 0
  $scope.$watch('files', ->
        $scope.uploadMulty($scope.files);
  )
  $scope.uploadMulty = (files) ->
    if (files && files.length)
      for file in files
        if (!file.$error)
          $scope.upload(file)


  $scope.upload = (file, endpoint) ->

    Upload.upload(
      {
        url: endpoint,
        data: {
          "profile.photo": file
          #name: file.name
        }
        method: 'PATCH',
        headers: { 'Authorization': 'JWT ' + localStorage.id_token },
        #withCredentials: true
      }
    )
    .then((resp) ->
        #console.log('Success ' + resp.config.data.file.name + ' uploaded');
        console.log('Success');
        console.log(resp);
      ,(resp) ->
        console.log('Error status: ' + resp.status);
      ,(evt) ->
        #$scope.upload_percentage = parseInt(100.0 * evt.loaded / evt.total);
        #console.log('progress: ' + $scope.upload_percentage + '% ' + evt.config.data.file.name);
    )

  #adresse
  $scope.paOptions = {
  	updateModel : true
  }
  $scope.paTrigger = {}
  $scope.paDetails = {}
  $scope.placesCallback = (place) ->
    console.log("hello")

  #languages
  $scope.LANGUAGES = languageMappingList


  #cursus
  year = new Date().getFullYear();
  $scope.years = [];
  $scope.years.push (year-i) for i in [1..age_max]

  $scope.cursus = {}
  $scope.cursus.items = []



  $scope.addItem = (item) ->
      item.push({
        medias:[]
        photo:"",
        name:""
      });

  $scope.removeItem = (items, num) ->
    items.splice(num,1)



  #first time application
  $scope.application.first_time = "true"


  #gallery
  $scope.artwork_galleries = {}
  $scope.artwork_galleries.items = []
  $scope.artwork_galleries.medias = []

  #console.log($scope.artwork_galleries)
)

.controller('AuthForm', ($scope, Authentification, jwtHelper, authManager) ->

  $scope.login = (params) ->
    Authentification.post(params).then((auth) ->
      #ok
      authManager.authenticate()
      tokenDecode = jwtHelper.decodeToken(auth.token)
      localStorage.setItem('id_token', auth.token)
      localStorage.setItem('user_id', tokenDecode.user_id)
      console.log(localStorage)

    , ->
      #error
      console.log("Error login");
      $scope.logout()
    )

  $scope.logout = () ->

    delete localStorage.id_token
    delete localStorage.user_id


    authManager.unauthenticate()

)
