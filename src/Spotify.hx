using haxe.Http;
using haxe.Json;

class Spotify {

    private var port:Int = 4370;
    private var localDomain:String = ".spotilocal.com";

    public var oauthToken(default, null):String;
    public var csrfToken(default, null):String;

    /**
      throws "Spotify Web Helper not running"

      throws "Spotify not running"
     **/
    public function new() {
        // TODO: Identify port which SpotifyWebHelper listens to

        // Confirm that the Web Helper is running
        var versionInfo:Dynamic;
        try
            versionInfo = getVersion()
        catch (msg:String)
            throw "Spotify Web Helper not running";

        // Confirm that the player is actually running
        if (versionInfo.running == false) {
            throw "Spotify not running";
        }

        oauthToken = getOauthToken();
        csrfToken = getCsrfToken();
    }

    /**
        Get version info about the current Spotify installation.

        May also include a flag telling if the Spotify player is NOT running.
        This flag is absent if the player IS running.
    **/
    public function getVersion():Dynamic {
        var httpRequest:Http = new Http(getSpotilocalUrl('/service/version.json'));
        httpRequest.setHeader("Origin", "https://open.spotify.com");
        httpRequest.setParameter('service', 'remote');
        #if debug trace(requestJson(httpRequest)); #end

        return requestJson(httpRequest);
    }

    private function getOauthToken():String {
        var response:String = Http.requestUrl("https://open.spotify.com/token");

        #if debug trace('Retrieving Oauth token. Response: ${response}'); #end

        return Json.parse(response).t;
    }

    private function getCsrfToken():String {
        var httpRequest:Http = new Http(getSpotilocalUrl('/simplecsrf/token.json'));
        httpRequest.setHeader("Origin", "https://open.spotify.com");

        #if debug trace('Attempting to get CSRF token. Response: ${requestJson(httpRequest)}'); #end

        return requestJson(httpRequest).token;
    }

    private function getSpotilocalUrl(path:String):String {
        return 'https://${generateHostName()}:${port}${path}';
    }

    private function requestJson(url:Http):Dynamic {
        var response:String;
        url.onData = function name(data) {
            response = data;
        }
        url.request();

        return Json.parse(response);
    }

    /**
     * @return a randomized subdomain of length ten in lowercase
     */
    private function generateHostName():String {
        var lowercase = "abcdefghijklmnopqrstuvwxyz";
        return [for (i in 0 ... 10) lowercase.charAt(Math.round(Math.random() * lowercase.length))].join("") + localDomain;
    }

    private function getRequestTemplate():Http {
        var template:Http = new Http(getSpotilocalUrl(''));
        template.setHeader("Origin", "https://open.spotify.com");
        template.setParameter("oauth", getOauthToken());
        template.setParameter("csrf", csrfToken);
        return template;
    }
}