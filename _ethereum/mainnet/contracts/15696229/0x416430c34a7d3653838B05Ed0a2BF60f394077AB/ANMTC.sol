
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ANiMAtttiC
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#BPYYYYPGB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BG5555555PPPPPPPPPB#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@#PJ?7?JY55PPPGGGPPPGGGPP5PB#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@#Y!!!?JY55555YYYYYYJJJJYYYYYJJ5G&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@&P7~!7?JJY55PPGGGBBBBBBGGGGPPP5YJJJ5#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@B?~!!7?J5PGGBBBBBBBBBBBBBGGPPPGGBBBGPPGB#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@#5!!!7JYPGGGGGGGGGBBBBBBBBBGGPPPP5PPGB###BBGGBB#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@&57!!7?JYJJ?77!!!!!!777?JJY5PPPPPGGGPPGBB######BPYP#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@#J7!~!JY7!~^^::::::::::::::::^^~!7?YPGGGGB#&#######BGG#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@YYP?!J57^:.........................:^75GGB#&&&########GG&@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@#?GBP?Y5!...                     ....::!G##B#&&&########BGB@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@PJB##GYPY.                     .....::^?######&&&#########BG&@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@55B#&#GYG7.                 .......::^7B#&#####&&&&&###&###BPB@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@YGB#&&&GYP?:.           .........:::^7B&#&&&###&&&&&&##&&###BYB@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@&5BBB#&&&PYB5!:...............::::^^!Y#&&##&&&##&&&&&&&##&&###G5B@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@P##BB#&&#PP##P!^:.......::::::^^~?5B&&&&##&&&&#&&&&&&&##&&&###PB#@@&&#G##&@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@P#&###&&&#5B&#PY5J7!~^^^^^~~!7J5G#&&&&&&##&&&&&&&&&&&&&#&&&#B#BP5JJ?77Y#BGB&@@@@@@@@@    //
//    @@@@@@@@@@@@@@@GB&##B#&&&BP&#PYG&##GBG5J5GGB####&&&&&&&#&&&&&&&&#&&&&&&#&&#BPY7777?JJB&&&#B#@@@@@@@@    //
//    @@@@@@@@@@@@@@@GG&&##B&&&&G#BPP5#&&##&B5P#B#####&&&&####&&&&&&&####&&&###BG5JJJYY5P5Y&&&&&&##@@@@@@@    //
//    @@@@@@@@@@@@@@@BP#&&#B#&&&#BG5B5G&&&##BGP#######&&&########&&&&###BBB###BGP55PPGGGGP5&@&&&####&@@@@@    //
//    @@@@@@@@@@@@@@@#PB####B&&&#BGGBGG#####BBGB######&&########BBBBGGGPPGBBBBGGGGGGGBBBGGP@@&&&#####&@@@@    //
//    @@@@@@@@@@@@@@@#5PPGGGGB##BGBBBBGGPPPPPPPPPPG#&&&&#####BBGPP55YY55PGBBGGGBBBBBBBBBBGG&&######BBPB@@@    //
//    @@@@@@@@@&&#G5J7!!!77?JY5PGGGGGP555555PPPGPG#&&&&#BBGPP55YYYY55PGGGBBBBBBBBBBBBBBBBGP5YJ????77???&@@    //
//    @@@@@@@&5??7!!!77???JJYY55PGGGGGGGGGGGGBBBBB&@&#GP55555555PPPGGBBBBBBBBBBBBBBBBBBBBGGPPP5Y?!~~!?G@@@    //
//    @@@@@@&PJ7???JJYY55PPPPGGGGGGGBBBBBBBBBBBBBB&&#P55555PPPGGGGBBBBBBBBBBBBBBBBBBBBBBBBGGGBG5JY5G#&@@@@    //
//    @@@@@@BG5Y555PPPGGGGGGGBBBBBBBBBBBBBBBBBBBBB&#GP5PPGGGGGGGBBBBBBBBBBBBBBBBBBBBBBBBBB#BB#&&@@@@@@@@@@    //
//    @@@@@@GBGGGGGGGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGBGPGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB###&@@@@@@@@@@@@    //
//    @@@@@@GBBGGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB#B&@@@@@@@@@@@@@    //
//    @@@@@#PBBGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB##BBBGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB#B@@@@@@@@@@@@@@    //
//    @@@@@BGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBPYYBBGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGPG@@@@@@@@@@@@@@    //
//    @@@@@BGPBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB?.:GBGPBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBY?B@@@@@@@@@@@@@@    //
//    @@@@@#5YGBGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBJ  YBG5GBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBYY&@@@@@@@@@@@@@@    //
//    @@@@@@BJJGGGGGGBBBBBBBBBBGBBBBBBBBBBBBBBBBBY  !BG55BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGG@@@@@@@@@@@@@@@@    //
//    @@@@@@@&#GGPPGGGBBBBBBBBBGBBBBBBBBBBBGBBBBBP. :PGPY5BBBBBBBBGBBBBBBBBBBBBBBBBBBBBBPB@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@&G5Y5PGGGGGBBBBGGBBBBBBBBBBBGGBBBBG:  JGPPYPBBBBBBBGGGBBBBBBBBBBBBBBBBBBGYB@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@GJ?Y55PPGGBBBGPGBBBBBBBBBBPPBBBBB!  ^PPPP5GBBBBBBBPPGBBBBBBBBBBBBBBGGP5J&@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@BJ7?JYY5PGGGG5PBBBGGBBBBB55BBBBB?   7GPGGPGBBBBBBG5PGBBBBBBBBBBGGGGPY?Y@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@&P777?JJ5PPPY5BBBGY5BBBB55BPPBB5.  .JPPGGPBBBBBBBPY5GBBBBBBGGGGPP5J77G@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@#57!77?JYYJJPBBG5JPBBB5YB55GBG^   :YPPGGPBBBBBBB5JYPGGGGGGPP55J?7!J&@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@#P?!!77?77JGGGGJJPBBPYG55GGG7    :YGPPGPGBBBBBGY?J5PGPP55YJ?7!!?#@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@&GY7!!!!!JPGPPJJPGPYGPYPPG5^^^~!JPGGPP5PBBBGGPY7?JY5YJJ?77!!Y&@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@#P?!~~!?5PP5?JPPYPPJ555GGGB#&&#PGGP5Y5GGGPP5?77????77!!!P&@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@&B5?!~7JYYJ7?YJ5PJJ55PPPGGB##BPGGP5JJPGP5JJ?!!!7!!!~?B@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@&B5?77???!7?J5JYPP555PGB###BPPGG5Y?Y5Y??77!!!!~!5&@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#GY?77!!?JJJY555PP5Y55JJ??5GGP5J?J?7!!!~~~?B@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BPJ?77??JYYYP#B5!~^^~~!JPGPYJ777!~~!?P&@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BY77JY5Y5&&?::...::^!JYYY?7!!~?G&@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&GJ7?JYJG#5:.    ..!J?P5J?!~Y&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&B5YYYYPG57^::^~JPPGBG5YYP&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&#######B#&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ANMTC is ERC721Creator {
    constructor() ERC721Creator("ANiMAtttiC", "ANMTC") {}
}
