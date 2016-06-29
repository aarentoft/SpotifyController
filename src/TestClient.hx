typedef Cmd = { cmd:String, help:String }
enum CmdType { Play; Pause; Unpause; VersionInfo; StatusInfo; Exit; Help; }

class TestClient {

    public static function main() {
        var cmds:Map<CmdType, Cmd> = [
            Play => { cmd: "play", help: "Play a Spotify URI. Example: >> play spotify:track:6JEK0CvvjDjjMUBFoXShNZ"},
            Pause => { cmd: "pause", help: "Pause currently playing track" },
            Unpause => { cmd: "unpause", help: "Unpause currently playing track" },
            VersionInfo => { cmd: "getVersion", help: "Get Spotify version info" },
            StatusInfo => { cmd: "getStatus", help: "Get status of Spotify (playing track, album, etc.)"},
            Exit => { cmd: "exit", help: "Exit the test client" },
            Help => { cmd: "help", help: "Displays this message"}
        ];

        var sp = new SpotifyController();

        while (true) {
            Sys.print(">> ");

            var cmd:Array<String> = Sys.stdin().readLine().split(' ');
            switch (cmd[0]) {
                case _ if (cmd[0] == cmds[Play].cmd): sp.play(cmd[1]);
                case _ if (cmd[0] == cmds[Pause].cmd): sp.pause(true);
                case _ if (cmd[0] == cmds[Unpause].cmd): sp.pause(false);
                case _ if (cmd[0] == cmds[VersionInfo].cmd): sp.getVersion();
                case _ if (cmd[0] == cmds[StatusInfo].cmd): sp.requestStatus(1);
                case _ if (cmd[0] == cmds[Help].cmd):
                    Sys.println('Available commands:');
                    for (i in cmds.keys()) {
                        Sys.println('\t${cmds[i].cmd} - ${cmds[i].help}');
                    }
                case _ if (cmd[0] == cmds[Exit].cmd): break;
                case _ : Sys.println('Unknown command. Type \'help\' for a list of available comands');
            }
        }
    }

}
