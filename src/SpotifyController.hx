using haxe.Http;
using haxe.Json;
using haxe.CallStack;

class SpotifyController {

    private var port:Int;
    private var localDomain:String = ".spotilocal.com";

    public var oauthToken(default, null):String;
    public var csrfToken(default, null):String;

    /**
      throws "Spotify Web Helper not running"

      throws "Spotify not running"
     **/
    public function new() {
        // Confirm that the Web Helper is running and in case it is, identify
        // the port it listens to
        var versionInfo:Dynamic = null;
        for (portCandidate in 4370 ... 4381) {
            try {
                port = portCandidate;
                #if debug trace('Trying port ${portCandidate}...'); #end
                versionInfo = getVersion();
                break;
            } catch (msg:String) {}

            if (portCandidate == 4380)
                throw "Spotify Web Helper not running";
        }

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

        return debugTraceReturn(requestJson, [httpRequest]);
    }

    /**
        Request current status of the Spotify player in JSON format

        `returnafter` Timeout in seconds. The server will respond when this time has
        passed IF none of the `returnon` events has occurred up until then

        `returnon` optional list of events. When one of these events occur, the server will
        respond even if the time `returnafter`has not passed since the request was made.
        Events supported *login*, *logout*, *play*, *pause*, *error* (*ap* is also supported,
        but its function is unknown to the the author)
    **/
    public function requestStatus(returnafter:Int, ?returnon:Array<String>):Dynamic {
        if (returnon == null) {
            returnon = [];
        }
        var httpRequest:Http = getRequestTemplate();
        httpRequest.url += "/remote/status.json";
        httpRequest.setParameter("returnafter", '${returnafter}');
        httpRequest.setParameter("returnon", returnon.join(','));

        return debugTraceReturn(requestJson, [httpRequest]);
    }

    /**
        Play the track with the uri `spotifyUri`
    **/
    public function play(spotifyUri:String):Dynamic {
        var httpRequest:Http = getRequestTemplate();
        httpRequest.url += "/remote/play.json";
        httpRequest.setParameter("uri", spotifyUri);
        httpRequest.setParameter("context", spotifyUri);

        return debugTraceReturn(requestJson, [httpRequest]);
    }

    /**
        Pause or unpause the currently playing track.

        `state` determines whether to pause or unpause.
    **/
    public function pause(state:Bool):Dynamic {
        var httpRequest:Http = getRequestTemplate();
        httpRequest.url += "/remote/pause.json";
        httpRequest.setParameter("pause", '${state}');

        return debugTraceReturn(requestJson, [httpRequest]);
    }

    private function getOauthToken():String {
        return debugTraceReturn(Json.parse, [Http.requestUrl("https://open.spotify.com/token")]).t;
    }

    private function getCsrfToken():String {
        var httpRequest:Http = new Http(getSpotilocalUrl('/simplecsrf/token.json'));
        httpRequest.setHeader("Origin", "https://open.spotify.com");

        return debugTraceReturn(requestJson, [httpRequest]).token;
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
     * Returns a randomized subdomain of length ten in lowercase
     */
    private function generateHostName():String {
        var lowercase = "abcdefghijklmnopqrstuvwxyz";
        return [for (i in 0 ... 10) lowercase.charAt(Math.round(Math.random() * lowercase.length))].join("") + localDomain;
    }

    private function getRequestTemplate():Http {
        var template:Http = new Http(getSpotilocalUrl(''));
        template.setHeader("Origin", "https://open.spotify.com");
        template.setParameter("oauth", oauthToken);
        template.setParameter("csrf", csrfToken);
        return template;
    }

    /**
        Convenience method which calls the function `funct` with the arguments `args`
        and prints the result of the function if haxe is in -debug mode.
        `customMessage` will be prepended to the `funct` result.

        Returns the result of `funct` with the arguments `args`
    **/
    private function debugTraceReturn(funct:Dynamic, args:Array<Dynamic>, customMessage:String=""):Dynamic {
        var result:Dynamic = Reflect.callMethod(this, funct, args);

        #if debug
        // Retrieve the file position of the debugTraceReturn call as this is more
        // informative than the file position down here in debugTraceReturn
        var debugMessage:String = '';
        switch (CallStack.callStack()[1]) {
            case FilePos(s, file, line):
                debugMessage = '${file}:${line}: ${customMessage}${result}';
            case _: trace('Could not recognize FilePos in callstack');
        }
        #if sys
        Sys.println('${debugMessage}');
        #else
        trace('${debugMessage}');
        #end

        #end

        return result;
    }

}