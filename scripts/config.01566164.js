(function(){"use strict";angular.module("sc2App").constant({soundcloudConfig:{apiBaseUrl:"http://api.soundcloud.com",apiKey:"fdb4bfea50165446d63c898644f6c475",redirectUri:"http://sc2.local:9000/callback.html",waveformServiceUrl:"http://wis.sndcdn.com/"},streamUrlServiceUrl:"http://wavetrip.org/services/redirecturl.php?callback=JSON_CALLBACK"}),angular.module("sc2App").config(["localStorageServiceProvider",function(a){return a.setPrefix("sc2")}])}).call(this);