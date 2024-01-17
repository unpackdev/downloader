
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 99 Diva
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    &&&&&&&&&&&&&#########BBB##GY~^..^!~^..^~^^~?5GPYY5PGPY?~^^~^..^!!^..^~JGB#BB#########&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&####BBBBBB#BP?^~~:::.:~!!?5GGBB############BGBBP?~~~:.:::^~^75B#BBB####B######&&&&&&&&&    //
//    &&&&&&&&&&&&##B##BBBBBBP7::::^~^:^75B#&&###&###################G5~~^^^:::::!5BBBBB##########&&&&&&&&    //
//    &&&&&&&#####BBBBBBBB#G7:.::::::75G######&&&&&&&&&&&&&&############BP?::::::.:!P#BBB####B####&&&&&&&&    //
//    &&&&&&&####BBBBBBBBBY^.::::::~JB###&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&####P7:::::..:JBBBB####B#####&&&&&&    //
//    &&&&&&&###BBBBBBBBB?..::...:!G#&&&&&&&&&&###&&&&&&&&&&&&&&&&&&&&&&&###B?^:..::..7BBB#####BB#&##&&&&&    //
//    &&&&&####BBBBBBBBB7..::.~7JG#&&&&&&&&&&&&##&&&&&&&&&&&&&&&&&&&&&&&&&####GY7^..:..7BBB######B#&#&&&&&    //
//    &&&&####BBBBBBBBB7^^~^:7G#&&#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&####P5^^^~^^?BBBB####BB####&&&    //
//    &&###&#BBBBBBBB#J..:::^P###&&&&&&&&&&&&&&&###&&&&&&&&&&&&&&&&&&&&&&&&&&###BG~::::::J#BBBBBB#B#####&&    //
//    &&###&#BBBBBBBBP:.:::..5##&&&&&&&&&&&&&&&####&&&&&&&&&&&&&&&&&&&&&&&&&&####B!.::::::PBBBBBBBBB#&###&    //
//    &&####BBBBBBBBB!.:::::!B#&&&&&&&&&&&&&&&########&&&&&&&&&&&&&&&&&&&&&&&&####B7:::::.!BBBBBBBBB#&###&    //
//    &&####BBBBBBBBP^^^^^?G#&&&&&&&&&&&&&&&&&&&###############&&&&&&&&&&&&&&&&####B57^~^~^GBBBBBBBB####&&    //
//    &&###BBBBBBBBBJ::~^5&#&&&&&&&&&&&&&&&&&&&########################&&&&&&&###B#&B#?^~^:YBBBBBBBBB#####    //
//    &&&##BBBBBBBBB7:.:!######&&&&&&&&&&&&&&&&&######BBBB##BBBBBBBB#####&&&&&&##B##B#B~:.:?#BBBBBBBB#####    //
//    &&&##BBBBBBBBB!^^:5&&##B#&&&&&&&&&&&####BBGBB##B#BBGGPPPPGGGGBBB#####&&&&##B####&J:^^7BBBBBBBBB#####    //
//    &&&##BBBBBBBBB!^:^5#&&&##&&&&&&&&&#BBBGGPPB###BBP555555555PPGGGGBB###&&&&###B###&5~:^7BBBBBBBBB#####    //
//    &&###BBBBBBBBB?^..!#&&&##&&&&&&&#BBBBGGPGB###BPY?77JJJYYYY5PPGGGGBB##&&&######&&#J..^?BBBBBBBBB#####    //
//    ######BBBBBBBBY~^:^JYYGB#&&&&&##BBBBGGGB###G5J?7~::!7??JJY55PPGGGBBB##&&&#####PPY!:^~YBBBBBBBB######    //
//    ###&##BBBBBBBBG~~~~~^~5&#B&&&##BBBBBB###BG5?77~^^^^^^!7??JY55PPPGGBBBB######B57^^~~~~GBBBBBBBB######    //
//    ###&&#BBBBBBBBBY!^::::!PBG#############BPY??7^^^~^^^^^~7??JY5PGGBBBBBBB##BB#5Y~:::^~YBBBBBBBB#####&&    //
//    ##&&&&#BBBBBBBBB?~:.:.:5BBB#BGB#####BBBGGPY?7^^^^^^^^^~7?JPGBBBGGGGGBBB##BGGY^::::^7BBBBBBBBB####&&&    //
//    ##&&&&##BBBBBBBBB7~:..~7JBBBBGBB#######BGPPY?!~~^^^^^~7?YPGGGBB###BBGBGBBGG7!~:.:^!GBBBBBBBB##&##&&&    //
//    ###&&&&#BBBBBBBBBB?~~~~^~5GBGPBBGGBB#BGG5?Y5J?7!~~~~!7?JY55J5PGB##BGGGGGBGY::~~~~!GBBBBBBBBB#&####&&    //
//    &#&&&&&##BBBBBBBBBBY!~::::!5G5GBGGPPPP5YJJ?JJ??!!~~!!7?JYYJJY55PPPPPGG5PY~:...^~?GBBBBBBBBB#######&&    //
//    ##&&&&&&##BBBBBBBBBBP7^:::.:??PBGGP5YJJJ??JJJJ?7!~~!7????JJJJJJJYY5PGGJ7:.:::^~YBBBBBBBBBB######&&&&    //
//    #&&&&&&&&##BBBBBBBBGGGY^:.::^?JGBGP5YJJJ???JYYJ7!^^!7JYJJJ?????JY5PGGY?:::::^?PBBBBBBBBBB####&&&&#&&    //
//    &&&&&&&&&&##BBBBBBBGBG7.:^^::7?YGBGP5YYJJJJYPPY?7~!7?Y5PYJ???JJY5PGGP7~::^^::?GBBBBBBBBB##&&&&&&&&&&    //
//    &&&&&&&&&#&&##BBBBBG5~:^~^:^~~!?PBBGPP5YYJJYPP5?7~!?J55PJ??JJYY5PGGGY!~^::^~^:!PBBBBBBB##&##&&&&&&&#    //
//    &&&&&&&&&&&&&&#BBBGJ~~!!!!77!!!?5GBGGPP5YYYJYGGG5YYPGGG5JJJJY55PGGG5!~7!!~~~~~~~5BBBB##&&&&&&&&&&&##    //
//    &&&&&&&&&&&&&&&##PJ77???J??77!7YYPGBGGPP5YYYY5PGPPPPPP5YJJYY55PPGGP?7!77??777!!!!YGB#&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&GYJJYYJJJ???JYYYBBGGGGGPP5555555JJJJ55555P55PPPGGPGY???77??JYYJ?7?Y#&#&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&#G5PG55YYYY?YPPY5####BGGGGPPGGBBBBGGGGGBBBGGPPPGGGGB##5JJYJJJJJYYYJYY5#&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&#BGGB#B555555GG5J5###B###BGGGPPPGGPP5555PPGPPPPPGGGB##B##YYY55YYYYYYGBG55#&&&&&&&&&&&&&&    //
//    &&&&&&&&&&#BBB####BP55PGBPYYP##B######BBGGGPPPPP555555PPPPGGGGB#B##B#BYY555555Y5BBBBPP#&&&&&&&&&&&&&    //
//    &&&&&&&&###########BPBBG55YPBB#######BBBGGGGPP5YJ???Y55PPGGGGGB#BB####B5Y555555PBBBBBBBB#&&&&&&&&&&&    //
//    &&&&&&#############BBGPP5YP###&##B##BBBGGPGGGP5YJJJJY55PGPPPGGB##BB####B5555555GBBBBBBBBBB#&&&&&&&&&    //
//    &&&&##########BPB##BGGG5YG&&###BB####BBGGPPPGGP55YY55PPGP55PGGB###BB####G55PPPPGBB#####BBBBB#&&&&&&&    //
//    &###########P5#B#BB#BBPP#&#######B#B##BGGP55PPPP5555PPPP555PGGB###BB#####BP55PPBBB#########BB##&&&&&    //
//    ############B##BB#BBBB#######B####BBBBBGPP555PP5YYY55555Y55PGBBB#B#B#B#####BGPGBB#####BB#########&&&    //
//    #############BPPB#BBBBBY5###B##BB#BBBGGBBP5YY555YYYY555YY55GBGGBBBBB##BB##BJ5BBB######GG##########&&    //
//    ##############B###BBBBB5G###B###BBBBBGGGBBPYY55YYYYYY55YY5GBGGGBBBBB##BBB#BJYGGB####################    //
//    ###################BBBB####BBB##BGGBGP5PGBGP5555YYYY5555PGBG55PGGGGB##BBB###BGGB####################    //
//    ######B############BBBBB###BBBB##BGPPGPYY5P5555YJJJJY555555YYPPPPGB##BBBB##BBBB#####################    //
//    ###G57Y#############BBBB##BBBBGB###GPPPPJJJJJ??7!!!!7??JJJJYPPPPG###BBBBBBBBBBB##############55B####    //
//    GY7~~^P##############B#BBBBBGGBGGBBBBGPP5JJJ7~~^^^^^^~~7?JJ5PPGBBBBGGGGBBBBBBB###############5~7J5G#    //
//    ~~~!?YB##############BBBBGB#BGGGGGGBGGGGG5J!^^^~~^^^^^^^!J5GGGGGGGPGGGGBBGGBBB###############BY7!!!?    //
//    !?PB&&#############BGGGGBB##BPPPGGPPPPP55Y?^^^~~^^^^^~^^^?PP55PPPPGGGGG###BGGGBBB###############G5?!    //
//    #&&&############BGGGGGBBBB###BPPPPPPPPP55J7^^^~~^^^^^~^^^7YY555PPPPPPG###BGGGGGGGGBB############&&#B    //
//    &&&##########BBGGGGGGBBBBBB###GPPPPGGGP55J?~^^^~^^^^~^^^~?Y55GGGGGPPGB##BGGGGGGGGGGGGB#############&    //
//    &&####&&#BBGGGGGGGGBBBBGGGGGGB#PPPGP5YYYYYJ?!~^^^^^^^^~!?JYYYYY5PPGGB##BGGGGGGGGGGGGGGGGB###&#######    //
//    ###&&#BGPPPPP5PGGGBBBBPPPPPGGGPG55YYYJYYJJYYJ7!!~~~~!!?JJYJJJYJJJY5PGPGGGGGGGGGGBGGGGPPPGG5PG##&####    //
//    &&#BGPPPGGPP5JYPGGP5PGPPP55PPG5GP55YYYJJYYYJJ???7!~!7??JJJYYYJJYY5YP55PPPPPPPPPGPPGG555PPGGPPPPG##&#    //
//    #BGPGGB##BG555Y?5GG5Y55555555PPPG5Y5YYYJJYJJ?!!~^^~^~~!7JJYJJJYYYY5PPP55555P555Y5GGY?Y5PP####BGPPG##    //
//    BGBB######BGPP5YJYGBG5555555555PPPYYYYYYJJJ?~^~^^~^~^~^~7JJJJYYYY5PP555555555YYPGPJ?Y55P########BBGG    //
//    &#&&#######BBPP55JJPGGP5555555555PPYJYYJJ?J!^^^^^^^^^^^^!J??JJYJY5P555555555Y5GG5?J5P5G#########&&##    //
//    &&&&&#######BBGPP5YJYPGP555555YYY5P5JJJYJ??7^^^^^^^^^^^^!?7JJJJJ5P555555555YPG5J?YP5PG#########&&&&&    //
//    &&&&&&&#######BBPPP5YYY555P5YYYYYY5P5??JYJ777!^^^~~^^^~!77JYJ??Y555YYYYYYP555YJY5PPGB#########&&&&&&    //
//    &&&&&&&&########BGPPP5YJJYP55YYYYYY555J?!!77777!!~~~!!77!!!77?J55YYYYYYY5YJJJY5PPGB#########&&&&&&&&    //
//    &&&&&&&&&&########BGPPPYYJJ5P5YYYYYYY5J7^^7??777!!~!!!7??7::7J5YYYYYYYYYJ??Y5PPGB##########&&&&&&&&&    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DIVA is ERC721Creator {
    constructor() ERC721Creator("99 Diva", "DIVA") {}
}
