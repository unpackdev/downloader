
/*
    ANYONE - THE LIVELY REALM OF THE UNSEEN

    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@&@@@@@@#&@@@@@&&@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@&5&@@@@PB@@@@&P@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@&&@@@@&&Y7GGGG?YGGGG7P#&@@@@&&@@@@@@@@@@
    @@@@@@@@@@@BYP55PPB7:JP5^?GGJ~YBGP55P5B@@@@@@@@@@@
    @@@@@@@@#G55PP?!JPG?.~^^~?77~~YPPY?YGGPPG#@@@@@@@@
    @@@@@&G55PBBBBG57~J77YGB#BB5?!7??5PGGGBBG55G&@@@@@
    @@@B5YPBBGPYJ?Y5J~:!G#G555YB#J.:~J5YJY5PGBGPY5B@@@
    &GYYPGGPPPPPPYJ^  :B&J5##G7?G&J   ~Y5PPPPPPPGPYYG&
    #Y?PGPPPPPPGPY?:  :##?P##&B?P&J   ^?YPPPPPPPPPPJY#
    @@#5J5PGGP5YJ?5P?~.!G#55555G#Y..~JP5YY5PGGGP5Y5#@@
    @@@@&GYYPGGGGGBB?~J7?5BB#BBPJ7?J7P#BGPPGGP5YG&@@@@
    @@@@@@@#P55PG5?7?5G?:^^^~!~^~?5P5J?YPGP55P#@@@@@@@
    @@@@@@@@@@#5YYJPGGB?:JPY:!55?~5BGGPYY5P#@@@@@@@@@@
    @@@@@@@@@@&&@@&#BGY!YPPG7JGPPY?PGB#&@@&&@@@@@@@@@@
    @@@@@@@@@@@@@@@@@&5&@@&&5B&&&@#P@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@&@@@@@@#&@@@@@&&@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

    ANYONE is a vibrant and community-driven crypto project. 
    Our core mission is to ascend as a frontrunner in the GameFi universe. 
    What sets us apart is the fusion of cutting-edge technology with meticulously crafted gameplay, 
    brought to life by renowned developers.

    Join Us:
    # https://any-one.tech
    # https://t.me/AnyonePortal
    # https://twitter.com/Any_one_ERC20
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract Anyone is ERC20 { 
    constructor() ERC20("Anyone", "ANYONE") { 
        _mint(msg.sender, 1_000_000_000 * 10**18);
    }
}