
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Eyal Carmi
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    &&@@@@@@&&&&&&###B##&&BBBBBGGGGGGGGPGGGGPPPPPPPPPGGPP555P5YYYY5PPPGGGGGP55PGGGGGGGGGBBBGPGGP555555YJ    //
//    &&&&@@@&#####BBBBBB###B###BGGGGGGGGGPPPPPPPPPPPPGGPP55555YYYYY5555PG5P5YYY5PGBGPPGGGGGGGPPPPP5PPPP55    //
//    &&&&@@&&&#####BBGGBB#BBBBBBGGGGGGGGGGPPPPGGPPPPGGGP555Y55Y5555PPPPPP55YJJJY5GGGPPPPGGPPPPPP5PPPPPPPP    //
//    &&@@@@&&&#####BGGBBGGBBBBBBBGGGGGGGGGGGGGPPGGGBBBBGP555GP5PPPPP55PP55YYJJJY5PGPPPPPPPP5555555PPPPPPP    //
//    @&&&@&&&###BBBBGPGGP5PGGGGGGGGPGGGGGGGGBBB#&######BBGGGBGGBBBGPPPP555YYJY5Y55555555PPP555Y55PPPPPGPP    //
//    &&##&&&&#BBGGGGBGPPP55GGGGPPGPPGGGGBB##&&&&&#B###BBBGGGBB###B#BBGGPP5JJJYY5P5YYYY5PPPPP5Y55PGGGGGGGG    //
//    B###&#&&&&#BBGGPP5555YY55P55PPPPGB#&&&#&&##B###BGBGGGGGBBBB####BBBBBPY5YYYY5P55YY5PPPGGPPPPGBBBBBBBB    //
//    B#&&#&&&&##BGPYYJJJJJJJJJY5555PB##&&&&&###BBBBBBBBPGGGGGGBBBBGGPPGBGPPP5YYYY55PPPP555PGBBBGGBBBB####    //
//    ##&&&##BBGP5P5555YJJJJYYYJY5PPGB#########&#BBBBBBBPGBGGGGGGGP555YYJYYYYPPPPPPPPGBGPGGGGGGBB#########    //
//    &&@&&###BBBGGPP5555YYYYYYJ5PPPGGGGB######&###BBBBBPGGGGGGPPP5YYJ7!!!!7?YP###BGGPPPGGGBBBBB###&&&&&&&    //
//    &&@&&&&###BBGPPPPP555Y5555P55PPPPPGBB##B##&&####BBGGGGGPP5YY7!~~:...::^~JGB##BGGGGGGGBBBB##&&@&@@&&&    //
//    &&@@@&&##BBGP555PPPPPPPGGPGP555PPPPGGGGB##&&&#&#BGPPGGGG5J?!^^::.. ..^^~?5GBB#BGGGBBBBBBB##&@@@@@@@@    //
//    #&@@@&###BGGPPGBBBGGGGGGPP555Y55PPPGGGGB##&&###BGGPPPPP5J?77!!!^^^:^~!7!JYPGG##BBBBBBBBB##&&@@@@@@@@    //
//    #&#&&&###BBGGGBBGGGP5555YYYY5Y5555PPPGGBB###BBGP55PPPPY?7!77!!!!7~!??????JJYPPGBGG#&#B##&&&@@@@@@@@@    //
//    &#BB#####BBGBBBBP5555YYYYY55555555PPPPGGGGGPP5YYJJJJJJ7!~~~!!!7?J?5555YJJ?JPGPBGPG#&&&&@@&&@@@@@@@@@    //
//    #BBGBB####BBBBBBGGGPP55YY??JYYYY55555555YYJJJJJ???777777777!77?JYJPGGP5PP55PBBBBB##&##&&&@@@@@@@@@@@    //
//    BBBBB##B##BGBBBGGGGGGP5YYJ?JJYYJJJJ?????????????????JYJJJJ????JYYYPPPPPPPPPPGBBBBBBB##&##&@@@@@@@@@@    //
//    BBGB##BBBBGPGGGGPGGGBPYY5555YJ?J?777!!~!!!!!!7777!77?JJJJYYYYYYYYY5PPGPPPGGBBBB##BBBBB###&@@@@@@@@@@    //
//    BBBBBBBBBBGGGGGGGPPGGYJJYYYJJ?J?77!!~^^^^^^~^^~!~~~~~!7??YYYYYYY5555PPPPGGBBBB###GGGBBB###&&@@@@@@@@    //
//    B###B##BBBBGGGGGGPPGPY?777?7??7!777!~^^^^:^^^^^^^^^^^~!7?JJJYYYY55P55PPGGGBBBB#&#GGGGGBBB#&&@@@@@@&&    //
//    ##BBB##BBBGGBGGGGGGBPPY?7!!!!7!!777~~^^^~~~!~!!!~!!~~!7??JJYYYJY5YJJY5PGGBBB##&&#BGGGGGBB##&&&@&@@&&    //
//    #BBBBBBBBGGGGGGBBBBBBPYJ?777!!~!!!!!~~~~~!!!7!!!7??777?????JJJJJJJ??JYPPGBPG#&&&BGGGGGGBB###&&&&&&&&    //
//    ####BBBBBGGGGBBBBBGGBB5Y??777777!!~!!~~~~~~!!!!!77!!!!!!!!777??JJYJ???JYPGGB##&BGGPJYPPGGBB##&&&##&&    //
//    ####BBBBBBBB##BBBBBGB#P5J??7!~~!~~~~~^^^~~^^~~~~~^^^:^~^^~~~~!7JJYJJ???J5PGB#BGPGGPYYY5GGBBBBB###B##    //
//    &@@&####B#########BBB#G5YJ?7!~~!~!!~~~~~^^^::::::::::^^^^^~~~!!7?????!!!7JGBBG5PPPYY5PPGGGGGGBBBBBGG    //
//    @@@&###&####&##&&###BBBP5J77~!~~~~~~!~~^^^^:..:^^:::::^^:^^^^~!!777?7!~:^!5BB5YPPPP55PPPGGGGPGGGPPPP    //
//    @@&&&&&@&&&&@@@@&&##B##BB5?!^^~~~^~~!!~^::^:..:^::.. ...  ...:^!7???7~^::~JGGJYPPPP5PGGPPPPPPPP555P5    //
//    B&##BGBBBB##&&@&&&#&&##B57^....:::::^~~~.:^~. ..:...:^:::..   .~7?JJ?7!~^!YGG??5P5PPGGGGPPPP5555555P    //
//    B####BBBBB##BPGGB#&&&&&GJ7~^^:.:~!!!~!!~:^!7~::~~~~~!7~~^^^^^^^^~7?JJ??77?YGPY5PP55PPPGGPPGGPP55YYY5    //
//    GB##BGBBPPG#BYYYG#&&&@@#GY7~~^:^^!!??!7?77^~!?7~77!7?J7~!!!77!!!7??Y5YYYJJ5GYGG55PPPPPPPPP5PPPP55555    //
//    5Y5B#GPGGPPPGPYPBBBBB#&&##GY?7?J5YJ?7!7J77~!7J77YY??JY555P55Y7~~?J!JY5PPYJY55PJJPPPPPPPP55555PP55P55    //
//    PPYJPBPP#&BBGGB&##B####PG555PPGGGPPP5YYYY?JY5GPPY5YJYYJJYYY5YJ~7J7:~7?JYGGPPPYY5PPPPPPPP555555555555    //
//    GGP5J5!?PBB#BBP5##&&&&#PP57!!7!~~!7?P5Y5J77?Y?J5JY5555YYYYY5YYJJ?::~7?JJ5PPGP5PPPPP555555555555555YY    //
//    GPPP5Y??YPB#BBP5B&#&#&&#G5!^::..::^~!P5?^~?GP??55YYYYJJJYYYYYYJ!. :^!?77J5GGPPP55555555YYYY555YYY5YY    //
//    GBG#GGGPGB&&#BB#@@#B#&&#G5!^..      .7~.. :7?Y557?!!!!!~~!!!~^.   .^!7?YPG#BBGGPPPP5555YYYYYYYYYYYYY    //
//    PPB#GGB####BB#&@@@@#&&#&&GJ!^.  .^^.:!!~.  ^!!JYJ!^:^!7!~~~~~~^:..:~?Y5PBB##BBGGGGPPP55555555YYYYYY5    //
//    JY5GBBB##&#B#@@@@@@@@@&&&#P?7~:..:~!7...   :7!~!JY!~~!YY??7!7!~~~!7Y5PBB##&#BGGGGGGGPPPPPPP55YY55555    //
//    J?J5G#&&###B&@@@@@@@@@@@@&&#GY??JY55?^:    .~^::7Y???7??????Y5Y??Y5PGB#&&&&GGGGGGGGGGGPPPPP55YYYY555    //
//    G5PBB#@@&##G&@@@@@@@@@@@@@@@@#PGPGBGGJ7:...^^~7J5Y7JJJYJJYJB&#PY??5G###&##BGBGGGGGGGGPPPPPP5YYYYYYYY    //
//    B##&&#&&#BBB@@@@@@@@@@@@@@@@@@#GBB#&&&P7!!7JJ5BGYJ7YY5Y7JP5PPY?JJJPB#&&@&#G5GBBGGGGGGGGPP5555YYYYYYY    //
//    ####&&BB###&@@@@@@@@@@@@@@@@@@@#BG&#&@#G#####GBB5J?PG5PGBB5JJJJJJ5GB##B&##PYYGBBBGGGGGGGGPP5YYYYYY55    //
//    B###&#BG#@@@@@@@@@@@@@@@@@@@@@&GGPBBB&GB&&B&#BPGGGBGGGGGBBG5P5YYY5B###&###PY??5BBBBBBBGGGPP555555YY5    //
//    BG###BBB&@@@@@@@@@@@@@@@@@@@@@&#BGPG#P?5PPY5Y5P55YJYJYPGBPPP#GPPPB#####&&BPY777J5GBBBBGGGGGPPPPPP555    //
//    PPGGGGB&@@@@@@@@@@@@@@@@@@@@@@&##BBGGG7~JY7!?YYJJJ7777Y5#B#PPP5#B#&&&@&#&#GY??777?YPGGGGGGGGPPPPP555    //
//    5PPGB&@@@@@@@@@@@@@@@@@@@@@@@@@&##GPB#Y?JJ7!777!~!7YYJYPB##GPPB##&&@@&&&&#G5JJ?7!!!!!77??JPGGGGGGPPP    //
//    PG#&@@@@@@@@@@@@@@@@@@@@@&#BBGP5PBBGGGBPPPPP555JYYYPGGP5PGBGPGB&&&&&&&&&##PYJ?77!!!!~~^^::~?YPGGGGGG    //
//    &&@@@@@@@@@@@@@@@@@&#G5J7~^:....~5GGGGP5PGB&&&&#####BGPGGPPPG##&&#&@&&&#BB5J?7777777!~^^. ...:~?PGGG    //
//    @@@@@@@@@@@@@@@&B5?~::.   .::^^:^7YPBGPP5YG##&#BGB#BBBGGGBGB&@&&&&@&&&&&#G5J?7777777!!~:.....   :!YP    //
//    @@@@@@@@@@@@&#5!^. .:.  ..^!7!~!77Y#&#G55GBB#BBBBBBB#B#B#&###&&@&@@&&&&BGP5Y???J?77~!~^:::..     .:~    //
//    @@@@@@@@@&BY?^^~:.::....:!?J7^~7~?B@@&##G#BBBGPG#####&&###&#&&&&&&&&&&&BG55P55PY?!~~^^^^:.        .:    //
//    @@@@@@&PJ7!~.^~^~!::^~^~?Y5?:^!^!P&@@@@&&&##&#G#&&#&###&B#&&&&#####@@@&##GGGPY?!^^^^^:...               //
//    @@@@&5!!!~~.^~^77~^!7!!JPGY!~^77YB&&@@@@@@@&@@&@@@@@&&&&&&&&&&&&&&&@@@&&#G57!~~~^^^:.                   //
//    @@@#?^J?^~:~?!??!7?JJ?JG#GY?^~Y55B@@@@@@@@@@@@@@@@@@@@@@&##&&&&&&@@@&&BPY7~^^^^^:..                     //
//    @@B!^5?:7^~5?5Y?JY5YY5B##G577JPPPB&@@@&@@@@@@@@@@@@@@@&&######&&@&BPY?!~~^^^::.....                     //
//    @#7^GG777!5P55J5PPP5G##BBPJJPPPGGB#&&&@&&@@@@@&&@@@@@&&&##&###BG5J7!~~^^^:...   ..                      //
//    @G~5#G5Y?P&&GJGBGPPP#&BBPJ?G##BBGB##&&@@@@@@@&&&@@@@@@@&&&#GP5?7!!~^^::..    .                          //
//    #Y!GB&GGB&@&P#&BP5P#&BGP5JP&@@&BGB#####&@@@@@@&&&&&&##BBGPY?7!^::::...                          ....    //
//    B?5B#&G#&@&G&@&B5P#&BGGPYG&@@@@#GGB##BGGBBBGGGPPPPP55YJ??7!~~^^:::..:....                      .^^:.    //
//    PYB#&#B#&&GB@@#P5B&#GPG5P&@@@@@#BBBBBBGGGGP5Y5YYYYYYJ?77!!!!~~~~^^^^::...                      .::::    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract EC is ERC721Creator {
    constructor() ERC721Creator("Eyal Carmi", "EC") {}
}
