
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 3D Nouns Figurines
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                           .?~:^.                                                                             //
//                                                                         ^JB@&&&Y                                                                             //
//                                                                        ?&&&&&&@P                                                                             //
//                                                                        Y&##&&&&&GGPY:                                                                        //
//                                                                        Y&###&&&&&@@@^                                                                        //
//                                                                        Y&#######&&&&Y7~~:                                                                    //
//                                                                        Y&#######&&&&@@@@!                                                                    //
//                                                                        Y&#########&&&&&@?..                                                                  //
//                                                                        Y&###########&&&&&#BB5                                                                //
//                                                                        Y&###########&&&&&&@@#                                                                //
//                                                                        Y&###############&&&&#5Y?7.                                                           //
//                                                                     :~^5&###############&&&&&@@@&.                                                           //
//                                                             .!5J?7!P&&&######################&&&&7~::.                                                       //
//                                                           ^JB@@@@@@@&&&&#####################&&&&&&&&BYJJ!!~^:..                                             //
//                                                        .?P&@&&&&&&&&&&&&&&&&#################&&&&&&&&@@@@@@&&&BBGP.                                          //
//                       ^JYY?7!^^:..                   ~Y#@@&&&&##&&&&&&&&&&&&&&&&&&&&&&&&&########&&&&&&&&&&&&&&&&&GGJ~^^                                     //
//                     !G&@@@@@@&&##BGG7             :?G&@&&&&&&&&#####&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@&&&7..                                  //
//                    .#&&&&&&&&&&&&&@@Y           !Y#&&&&&&&&&&&&&&&###############&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&P                                  //
//                    .G###########&&&@B???~.   ^?G@@&#######&&&&&&&&&&&&&&&&&&&&&###############&&&&&&&&&&&#&&&&&&&&&&&&&&&@&G~                                //
//                      :::G&######&&&&&@@@@: !Y#&&&&&&&&&&&&##########&&&&&&&&&&&&&&&&&&&&&&&&##########&&&###&&&&&&&&&&&&&&&@BPY                              //
//                         G&##########&&&&&JG&&&#####&&&&&&&&&&&&&&&###############&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@#7!                            //
//                         G&###########&&&&&&##&&&&&&&&#&&&&&&&&&&&&&&&&&&&&&&&&&###############&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@#.                           //
//                         B&&&&########&&##&&&&#BB##########&&&&&&&#&&&&&&&&&&&&&&&&&&&&&&&&&&############&&&####&&&&&&&&&&&&&&&&@#.                           //
//                         ~7?JG&########&&&&&&#YYYY5555PPPGGGGBBB#######&######&#&&&&&&&&&&&&&&&&&&&&&&###&&&&&&&&&&&&&&&&&&&&&&&@#.                           //
//                          .?P#####&&&&&&&&##&BJJJJJJJJJJJJJYYYY5555PPPGGGB#&&#######&&&&&&&&#&#&&&&&&&#####&&&&&&###&&&&&&&&&&&&&&^                           //
//                         Y#&&&####BBB######&&BJJJJ7!7???JJJJ?????JJJJJJYGB&B555PPPPGGGBBB#B######&#&@&&&&#####&&&&&#&&&&&&&&&&&&&@?:.                         //
//                         G&######5YY555PPPGGGGJJJJ^  . ...^GBGGPP5YYJJJJGB&G?JJJJJJJJYYYYY55PPPPGGGBBB##&&####&&&&&&&&&&&&&&&&&&&&&@?                         //
//                        ^B&####&#JJJJJJJJJJJYJJJJJ^        #@@@@@@@#JJJJGB&GJJJJ???JJJJJJ??JJJJJJJYYY5GB&&########&&&&&&&&&&&&&&&&&@#P:                       //
//                     .?G&&#####&#JJJJYYYJJJJJJJJJJ^       .#@@@@@@@#JJJJGBBGJJJJ^..::^^^!PP55YYJJJJJJYGB&&&&&&####&&&&&###&&&&&&&&&&@@:                       //
//                   ~?B&&&######&#JJJJGB###BBBPJJJJ^       .#@@@@@@@#JJJJYY5YJJJJ:       :@@@@@@&&GJJJYGB###&&&&###&&&&&&&&&&&&&&&&&&&&:                       //
//                :?G&@&#########&#JJJJGB75&&&&#JJJJ^       .#@@@@@@@#JJJJJJJJJJJJ:       :&@@@@@@@BJJJYGB####&&&###&&&#&&&&&&&&&&&&&&&&:                       //
//               .B&&&&##########&#YJJJGB:?&##&BJJJJ^       .#@@@@@@@#JJJJ5PPYJJJJ:       :&@@@@@@@BJJJYGB####&&&###&&&###&&&&&&&&&&&&&&G                       //
//               .B#&&&&&&&&&&&&@&G7!!?Y~ J@&#&BJJJJ^       .#@@@@@@@#JJJJGB&BJJJJ:       :&@@@@@@@BJJJYGB####&&&###&&&&&&&&&&&&&&&&&&&&&P?.                    //
//                .:^~!77YYYPGBB5~        !PG#&BJJJJ~...     #@@@@@@@#JJJJGB&GJJJJ:       :&@@@@@@@BJJJYGB####&&&######&&&&&&&&&&&&&&&&&&@&.                    //
//                            ..            :#&BJJJJJ???77!!!PB##&&&@#JJJJGB&GJJJJ:       :&@@@@@@@BJJJYGB####&&&#######&&&&&###&&&&&&&@@#Y.                    //
//                                          .#&#P55YYYJJJJJJJ??JJJJJYYJJJJGB&GJJJJ:       :@@@@@@@@BJJJYGB####&&&#######&&&&&####&&&@@&P!.                      //
//                                          .GB#&&&###BBBGGPP555YYYJJJJJJJGB&GJJJJ?!!!~~^:~#&@@@@@@BJJJYGB####&&########&&&&&&&&&&@@#Y~                         //
//                                           . J&####&&&&&&&&&&&###BBBGGPP##&BYJJJJJJJJJJJJJJYYY55GPJJJYGB&&##&#########&&&###&@@&P7.                           //
//                                             J&&#################&&&&&&&&&&####BBBGGP555YYJJJJ???JJJJYGB&&############&&&&&&&BJ^                              //
//                                             J##&&&&##################&BB#&!:~~7??55PGG#B###BBBBPJYYJ5B#&&&&&&&&&&####&&@@&P~.                                //
//                                             ..:^~7P&&&&&############&&J.:~.         ..::^~~77??^..::^~~77JYYPGBB###&&&&B?:                                   //
//                                                   ?BBB#####&&&&&&&&#PB?    ...... .                         .7?^:^^JYJ~                                      //
//                                                   JPPPP5PPP55PPPGGBB:..                  .............  .^: .~^~!~^^.                                        //
//                                                   JPPPPPPPGJ?????????77!!!~~^^:.......               .  .7^ ...7JP7                                          //
//                                                   !???JJJJY5555YYJJJJJJJ????????????77!!!~~~^^^::..   :!~^:.^7JGGB7                                          //
//                                                   7J???????5GGGGGGGPPPPP555YYYYJJJJ??????????YGGG5YJ?7?JJJ????JGB#7                                          //
//                                                   YGPPP5555YJYY555P5PPPPPGGGGGGGPPPPP55555YYJYB##BGGGGGPPPPPP5P##&7                                          //
//                                                   JPPPPGGGGY??????????JJJYYY5555PPPPPPGGGGGGPG###PY55555PPPPPPG#BB7                                          //
//                                                   7JJJJJYY5P5YYYJJJJJ??????????????JJJYYY5555PBGGY7???????JJJJ5GGB7                                          //
//                                                   7????????PGGGGGPPPPPP555YYYJJJJ????????????JGGGG55YYJJJ?????JGB#7                                          //
//                                                   JPP555YY55YY555PPPPPPGGGGGGGPPPPPP555YYYJJJYBB####BGPPPPP5555##&7                                          //
//                                                   JGPPGGGGGY???????JJJJJYYY555PPPPPPGGGGGGGPPG###BGGGGPPPPPPGGG#BB7                                          //
//                                                   7JJJYYY55PYYYJJJ??????????????JJJJJYY5555PPGBBGGGGBBJ?JJJJYY5BGG7                                          //
//                                                   !????????GGGGPPPPPP5555YYJJJJ??????????????YGGGBB###J???????JGG#7                                          //
//                                                   JP555YYYY5Y555PPPPPPGGGGGGPPPPPP555YYYJJJJ?YBB####BGPPPP555Y5B#&7                                          //
//                                                   YGGGGGGGGY??????JJJJYYY555PPPPPPGGGGGGGPPPPG###BBGGGPPPGGGGGG###7                                          //
//                                                   7YJYYY55P5JJJJJ??????????????JJJJYYY555PPPPG#BGGGGBBJJJJJYYYPBGG7                                          //
//                                                   !???????JGGGPPPPP5555YYYJJJ???????????????JYGGGBB###J???????JGGB7                                          //
//                                                   J555YYYJYP5PPPPPPPGGGGGGPPPPPP5555YYYJJJ???JGB####BGP55555YY5B#&7                                          //
//                                                   YGGGGGGPGY?????JJJYYY5555PPPPPGGGGGGGPPPPPPP####BGGGPPGGGGGPG###7                                          //
//                                                   ?YY55555P5JJJ???????????????JJJYY55555PPPPPG#BGGGGBBYJYYY555PBGG7                                          //
//                                                   !???????JGPPPPPP555YYYJJJJ???????????????JJYGGGGB###J???????JGGB7                                          //
//                                                   YPP5YYJJJPPPPPPGGGGGGGPPPPPPP55YYYJJJJJ????JGBB###BB555YYYJJYB#&?                                          //
//                                                   P&&&&&###5??JJJJJYYY55PPPPPPPGGGGGGGPPPPPP5P####BGGGGGGGGGGPG###7                                          //
//                                                   P&##&&&&&Y7??????????????JJJJYYY555PPPPPPPPG#BBGGGB5JYYY555PPBGB!                                          //
//                                                   P@&&&@#5~  ..YP555YYYJJJ??????????????JJJJJ5BGGGBB#Y!???????JGGB7                                          //
//                                                   7YYPPJ:      5GPGGGGGPPPPPP555YYYJJJJJ?????JGGGB###Y5G555YYJYB#@?                                          //
//                                                                5GPPPPPPPPPPGGGGGGGGPGPPPPPP555GPPB###5B@&&&&&##&&@?                                          //
//                                                                5GPPPPPPBBBBY!?JJ555PPPGGGPPGGPPPPB###Y7JJ5#&##&&&@?                                          //
//                                                                5GPPPPPPB##&?      .::^^^?GPPPPPPPB##&Y    G&&&&@@&!                                          //
//                                                                5GPPPPPPB##&?            :GPPPPPPPB##&Y    5GB##G!:                                           //
//                                                                5GPPPPPPB##&?            ^GPPPPPPPB##&Y      ...                                              //
//                                                                5GPPPPPPB##&?            ^GPPPPPPPB##&Y                                                       //
//                                                                5GPPPPPPB##&?            ^GPPPPPPPB##&Y                                                       //
//                                                                5GPPPPPPB##&?            ^GPPPPPPPB##&Y                                                       //
//                                                                5GPPPPPPB##&?            ^GPPPPPPPB##&Y                                                       //
//                                                                5GPPPPPPB##&?            ^GPPPPPPPB##&Y                                                       //
//                                                                5GPPPPPPB##&?            ^GPPPPPPPB##&Y                                                       //
//                                                                5GPPPPPPB##&?            ^GPPPPPPPB##&Y                                                       //
//                                                                5GPPPPPPB##&?            ^GPPPPPPPB##&Y                                                       //
//                                                                5GPPPPPPB##&?            ^GPPPPPPPB##&Y                                                       //
//                                                                5GPPPPPPB##&?            ^GPPPPPPPB##&Y                                                       //
//                                                              ^YBBBBBBGGB##&?            ^GPPPPPPPB##&Y                                                       //
//                                                              ?BGGGGGGG###GJ:            ^GGPPPPPPB###Y                                                       //
//                                                              !Y55PPPGG#5!              !PBBBBBGGGB##&Y                                                       //
//                                                                ...::~~~                5GGGGGGGG###GJ:                                                       //
//                                                                                        ?55PPPGGGBY!                                                          //
//                                                                                           .::~~7:                                                            //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract THREEDNF is ERC721Creator {
    constructor() ERC721Creator("3D Nouns Figurines", "THREEDNF") {}
}
