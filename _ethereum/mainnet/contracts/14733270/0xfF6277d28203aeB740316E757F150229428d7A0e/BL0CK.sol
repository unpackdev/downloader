
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bl0ckstone
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                  //
//                                                                                                                                                                  //
//         &&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&##############BBBBBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGGGGPPPPPPPPP5555555YY                                 //
//         &&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&###########BBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGGGGGGGGGGGPPPPPPP555555555555                                 //
//         &&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&&&#########BBBBBBBBBBBBBBBBBBBGGGGGGGGGGGGGGGGGGGGGPPPPPPPP5555555555PPP                                 //
//         &&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&&&&&&######BBBBBBBBBBBBBBBBBGGGGGGGGGGGGGGGGGGGGGGPPPPPPPPPPPPPPPPPPPPPPP                                 //
//         &&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@&&&&&&&&&&&&&&&&&&######BBBBBBBBBBBBBBBGGGGGGGGGGGGGGPPGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP                                 //
//         &&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@&&&&&&&&&&&&&&&&&&&#####BBBBBBBBBBBBBGGGGGGGGGGGGGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP                                 //
//         &&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&&&&#######BBBBBBBBBBBBBBBGGGGGGGGGGGPPPPPPPPPPPPPPPPPPPPPPGPPPPPPPPPPPPPPPPP                                 //
//         &&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&##########BBBBBBBBBBBBBBBGGGGGGGGGPPPPPPPPPPPPPPPPPPPPPPGGGGGGGPPGGGGPPPPPPPP                                 //
//         &&&&&&&&&@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&###########BBBBBBBBBBBBBGGGGGGGGGGGGGPPPPPPPPPPPPPPPPPPPGGGGGGGGGGGGGPPPPPPPPP5                                 //
//         &&&&@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&##########BBBBBBBBBBBBBBGGGGGGGGGGGGGGGGGPPPPPPPPPPPPPPPPPGGGGGGGGGGGPPPPPPPP5555                                 //
//         @@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&###########BBBBBBBBBBBBBGGGGGGGGGGGGGGGGGGGGGGGPPPPPPPPPPPPGGGGGGGGGGPPPPPPPP555555                                 //
//         @@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&#########BBBBBBBBBBBBBBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPPPPPPPPPGGGGGGGGPPPPPPPPP55555555                                 //
//         @@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&#########BBBBBBBBBBBBBGGGGGGGGGGGGGGGGBBBBBBGGGGGGGGGGGGGGGGGGGGGGGGPPPPPPPPPP5555555555                                 //
//         @@@@@@@@@@@@@@@@@@@@@@@&&&&&&&#########BBBBBBBBBBBBBBGGGGGGGGGGGGGGGGBBBBBBBBBBBBBGGGGGGGGGGGGGGGGPPPPPPPPP5555555555555                                 //
//         @@@@@@@@@@@@@@@@@@@@@&&&&&&&&&######BBBBBBBBBBBBBBBBBBGBBGGGGGGGGGGGBBBBBBBBBGGGGGGGGGGGGGGGGGGPPPPPPPPPPPP55555555555YY                                 //
//         @@@@@@@@@@@@@@@@@@&&&&&&&&&&&&####BBBBBBBBBBBBBBBBBBBBBBBBBBBGGGBBBBBBGGGGP5Y5PGGGGGGGGGGGGGGPPPPPPPPPPP555555555555555Y                                 //
//         &&&&&&&&&&@@@@@&&&&&&&&&&&&&######BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGJ^.   .:~5GPGGGGPPPPPPPPPPPPPPP55555555555555555                                 //
//         &&&&&&&&&&&&&&&&&&&&&&&&&&&&#####BBBBBBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGGP^         .5PPPPPPPPPPPPPPPPPP5555555555555PP5555                                 //
//         &&&&&&&&&&&&&&&&&&&&&&&&&&&#####BBBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGGGGPGJ           !PPPPPPPPPPPPPP5555555555PPPPPPPPPP555                                 //
//         &&&&&&&&&&&&&&&&&&&&&&&&######BBBBBBBBBBBBBBBGGBBBBBBGGGGGGGGGGGGGPPPP5:           ?PPP5PP55PP5555555555PPPPPPPPPPPPP555                                 //
//         &&&&&&&&&&&&&&&&&&&&&#######BBBBBBBBBBBBBBGGGGGGGGGGGGGGGGGGGGGPPPPPPP5.          ^5P555555555555555555PPPPPPPPPPPPP5555                                 //
//         &&&&&&&&&&&&&&############BBBBBBBBBBBBBGGGGGGGGGGGGGGGGGGGGGPPPPPPPPPPPJ.        ~GPP55555555555555PPPPPPPPPPPPPP5555555                                 //
//         &&&&&&&&&&############BBBBBBBBBBBBGGGGGGGGGGGGGGGGGGGGGGGGPPPPPPPPPPPPPP5:       ^GPPPPPP5555PPPPPPPPPPPPPPPPPP55555555Y                                 //
//         &&&&&&&#########BBBBBBBBBBBBBBBGGGGGGGGGGGGGGGGGGGGGGGGGGPPPPPPPPPPPPPPGG5        :~7?!?Y5PPPP5555PPPPPPPPP555555555YYYY                                 //
//         &&&&#########BBBBBBBBBBBBBBGGGGGGGGGGGGGGGGGGGGGGGGGGGGPPPPPPPPPPPPPGPJJ7^                 :7555555555555555555555YYYYYY                                 //
//         &&&########BBBBBBBBBBBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPPPPPPP5J^                        :Y55555555555555555YYYYYYYY                                 //
//         &########BBBBBBBBBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPPP5~.                           :55555555555555555YYYYYYYY                                 //
//         &&#####BBBBBBBBBBBGGGGGGGGGGGGBBBBBGGGGGGGGGGGGGGGGGGGGGGGGGGGGP:                              ?5555555555555555555YYYYY                                 //
//         ########BBBBBBBBBBBBGGGGGGGGGBBBBBBBBBGGGGGGGGGGGGBBBGGGGGGGGGG7                               .J555555555555555555YYYYY                                 //
//         #########BBBBBBBBBBBBBBBBGBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGG!                                 75555555555555555YYYYY5                                 //
//         #######BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGGGGY                                  J555555555555555555555                                 //
//         ######BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGGGGPPG7                                  :555555555PP5555555555                                 //
//         #####BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGGGGPPPPPPPP.                            !      7P55PPPGPPPPPPPPPPP55                                 //
//         #BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGGGGPPPPPPPPPPPG?                            ^PJ     .5PPPGGGGPPPPPPP55555                                 //
//         BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGPPPPPPPPPPPPP555PP.     Y                     .55P?     ~PPPPPPPPPP55555YYYY                                 //
//         BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGPPPPPPPPP5555555555P!     7P                     JP5PY     .55555555555YYYYYYJJ                                 //
//         BBBBBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGGGPPPPPPPP555555555555555J     .G7                    .PPPP5.    .5555555YYYYYJJJJJJJ                                 //
//         BBBBBBBBBBBBBBBBBBBBBBGGGGGGGGGGPPPPPPPPPP5555555YYYYYYYYYY5:     YP                     ~P555P!    ^P5555YYYYYYJJJJJJJJ                                 //
//         BBBBBBBBBBBBBBBBBBBBBGGGGGGGGPPPPPPPPPPPPP555555YYYYYYYYYYYY     !G5                     ^P5555J    ?5555555YYYYYYYYYJJJ                                 //
//         BBBBBBBBBBBBBBBBBGBBGGGGGGGPPPPPPPPPPPPPPPPPP5555P5555Y555P7    !PPP                      J5555J    Y555555555YYYYYYYYJJ                                 //
//         GGGBBBBBBBBBBBBBBBBGGGGGGGGGPPPPGGGGGGGGGGGGGGGGBGGGGPPPPPG:   ?GGG7                      :5555~   .5555555555YYYYYYYJJJ                                 //
//         GGGGGBBBBBBBGGGGGGGGGGGGGGGGGGGGGGGGBBBBBBBBBBBBBBBBBBGGGGY   ?GPG7                        JP?.    ?P555P55555YYYYYYJJJJ                                 //
//         GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBBBBBBBBBBBBBBBBBBBBBBBGGGG~  7GPPP7                        ^!      YP5P5J?7~^....:....:~                                 //
//         PPPPPPPPPPPPPPGGGGGGGGGGGGGGBBBB########BBBBBBBBBBBGGGGGPP.  JGPPP7                          !.   .PP57:            . .                                  //
//         5555PPPPPPPPPPPPPPPPGGGGGGGBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGP.   YPP?                         .!.////.JPY7^.                                                //
//         YYY555555555555PPPPPPPPPPGGGGGGGBBBBBBBBBBBBBBBBGGGGGGGGGP. :.:PP?:                            .....                                                     //
//         JJJJJYYYYYY5YY5YY55555555PPPPPPPPPGGGGGGGGGGGGGGGGGGGGGGGG7 ^!.YPPJ                                                                                      //
//         ?????????????JJJJJJJJJJJYYYYYY55555555PPPPPPPPPPPGGGGGGGGGG7:.^PPP:                                                                                      //
//         ??7777777!7777777777777?????JJJJJJYYYYYYYYYYYYY555PPPP55PPPPPPPPP5.                                                                                      //
//         YJ???777777?J5YJ??JJJJYYYJY5PGPPPP5555555YYYYYJJJYJYYYYY5YY55JYY7:                                                                                       //
//         BGGPPPPPPP55PPP55PPP55PPGGB##&#BBGGBBBBBBBBBBP55555P55J!~:^J!...                                                 .                                       //
//         GGGGGGGGGGPP555YYY55555PPPGGBBGGGGGGBBBGGGGGGGPJJPGJ?77.                                         .      ....    .                                        //
//         GGGPPPPGGPPPPPPPPPPPPPPPPPPGGGGGGGGGGGGGGGJJY7!. .!.::.                                                    .  ...                                        //
//         GPPPPPPP55555555555YYYYYYYYYYY5555Y55555JJ^.:. .                              .                       .   .           .                                  //
//         JJJJJJJ?????????????????????????????????^..                                                       .   ...                                                //
//         !!!~~~~~~~~~~~~~~!!!!!!~~~~!!!!!~!!!~^~^.                                      .         ...............                                                 //
//         ^^^^::::::::^^::^^^^^^^^^^^^~^.~^^:.:              .  ..                        .        ..........::...                                                 //
//         ~^^^::^:::::::^:^^^^^^^:...  . .           ......    .   .... ........          .         ............. .                                                //
//         :::   .:^:::::::::::::.          .    .... .... ..   ...................                  ........    ..                                                 //
//           .    ...:::::::: ..       .......... .   .  .........::....:...........      .          ..  ..                                                         //
//                   :..            ..     .. ......... ..........:..  ...:::....:..                                                                                //
//              ......                    ...................:::..............                                                                                      //
//               ..           ..   .     .....................::....   ......                           .                                                           //
//                      ...     ... .   ...:........:.............  ....^:...   .                                                                                   //
//         .  ....      ......  ....    .....................   ............       .                                                                                //
//         ..  ..    .  ..:... .... ......  .   ..    ......  . ..   ......                                                                                         //
//         ...       . ..... ...........     ..   .  ....... .:. . ...  .                                                                                           //
//         .......        .   ....... .       .. ......:.... ... .            .                                                                                     //
//         ....                    ..    ......: .......:. ..       .                      P A R A L L E L  S P A C E S                                             //
//         .::                    ...     . ....  . .......  ..     .                          :  ::  :::  :::::                                                    //
//         ....  ..                       .      ..   ..      .                             B Y   B L 0 C K S T O N E                                               //
//         ..:.. .                     .      .     ...       .                                                                                                     //
//         ...  ...  .    .    .    ....    .              :.               .                                                                                       //
//              ..      ..                ...                .                                                                                                      //
//            .        .                            ..                                                                                                              //
//                                         .                                                     ..                                                                 //
//         ..            .          .                   .   .. .                                                                                                    //
//                                 ..                        ..                                                                                                     //
//          .                                                                                                                                                       //
//         .                                                                                                                                                        //
//         .                                          .                                                                                                             //
//                                                                                                                                                                  //
//                                                                                                                                                                  //
//                                                                    .                                                                                             //
//                                                                                         .                   ....                                                 //
//          .. .                                         .                                 . ..               .   ..                                                //
//                                 ..                                         .           .  .                                                                      //
//                .        .          .                                        .       ..      .                                                                    //
//                                                                                                                                                                  //
//                                                                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BL0CK is ERC721Creator {
    constructor() ERC721Creator("Bl0ckstone", "BL0CK") {}
}
