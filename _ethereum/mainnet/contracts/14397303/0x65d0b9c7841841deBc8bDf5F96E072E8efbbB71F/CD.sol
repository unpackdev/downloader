
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Non-Fungible CDs
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//       ███╗░░██╗░█████╗░███╗░░██╗░░░░░░███████╗██╗░░░██╗███╗░░██╗░██████╗░██╗██████╗░██╗░░░░░███████╗       //
//       ████╗░██║██╔══██╗████╗░██║░░░░░░██╔════╝██║░░░██║████╗░██║██╔════╝░██║██╔══██╗██║░░░░░██╔════╝       //
//       ██╔██╗██║██║░░██║██╔██╗██║█████╗█████╗░░██║░░░██║██╔██╗██║██║░░██╗░██║██████╦╝██║░░░░░█████╗░░       //
//       ██║╚████║██║░░██║██║╚████║╚════╝██╔══╝░░██║░░░██║██║╚████║██║░░╚██╗██║██╔══██╗██║░░░░░██╔══╝░░       //
//       ██║░╚███║╚█████╔╝██║░╚███║░░░░░░██║░░░░░╚██████╔╝██║░╚███║╚██████╔╝██║██████╦╝███████╗███████╗       //
//       ╚═╝░░╚══╝░╚════╝░╚═╝░░╚══╝░░░░░░╚═╝░░░░░░╚═════╝░╚═╝░░╚══╝░╚═════╝░╚═╝╚═════╝░╚══════╝╚══════╝       //
//                                                                                                            //
//                                         ░█████╗░██████╗░░██████╗                                           //
//                                         ██╔══██╗██╔══██╗██╔════╝                                           //
//                                         ██║░░╚═╝██║░░██║╚█████╗░                                           //
//                                         ██║░░██╗██║░░██║░╚═══██╗                                           //
//                                         ╚█████╔╝██████╔╝██████╔╝                                           //
//                                         ░╚════╝░╚═════╝░╚═════╝░                                           //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                        .:^~!7??JJYYYYYJJ??77~~^:.                                          //
//                                   :^!?Y5PPPGGGGGPPPPPPPPPPPPP5555YJ?7~^.                                   //
//                              .^7J5PGGGGGGGGGGPPPPPPPPPPPP555555555555555J?!:.                              //
//                           :!JPGBBGGGGGGGGGGGGGPPPPPPPPPPP5555555555555555555Y?~:                           //
//                        :7YPGGGGGGGGGGGGGGGGGGGPPPPPPPPPPP55555555555555555555PP5Y!:                        //
//                     .!YPGGGGGGGGGGGGGGGGGGGGGGGPPPPPPPPPP555555555555555555555PPPPPY!.                     //
//                   ^?PGGPPPPPGGGGGGGGGGGGGGGGGGGPPPPPPPPP55555555555555555555PPPPPPPGGP?:                   //
//                 ^JPPPPPPPPPPPGGGGGGGGGGGGGGGGGPPPPPPPPPP555555555555555555PPPPPPPGGGGPP5?:                 //
//               :JPPPPPPPPPPPPPPGGGGGGGGGGGGGGGGPPPPPPPPPP55555555555555555PPPPPPPGGGPP5555Y7:               //
//             .75PPPPPPPPPPPPPPPPPGGGGGGGGGGGGGGGPPPPPPPPP5555555555555555PPPPPGGGGPP55YYYJJJJ!.             //
//            ^Y555555PPPPPPPPPPPPPPGGGGGGGGGGGGGGGPPPPPPP5555555555555555PPPPPGGPPP55YYJJJ?????7:            //
//           !555555555PPPPPPPPPPPPPPGGGGGGGGGGGGGGPPPPPPP55555555555555PPPPPGGGP555YYJJ??77!!!!!7~           //
//         .?P5555555555555PPPPPPPPPPPPPGGGGGGGGGGGGPPPPPP5555555555555PPPPGGGP55YYJJ??777!!~~~~^^~!.         //
//        .J5555555555555555555PPPPPPPPPPGGGGGGGGGGGPPPPPP555555555555PPPGGGP55YJJ??77!!!~~^^^::.. :!.        //
//       .JP55555555555555555555PPPPPPPPPPPGGGGGGGGGGGPPPPP555555555PPPPGPP5YYJJ?77!!!~~^^::..      :!        //
//       7P555555555555555555555555PPPPPPPPPGGGGG5J???JY55PPGGPP555PPPGPP5YYJ??7!!~~^^::..        ...~!       //
//      ~P555555555555555555555555555PPPPPPPGGPY7!~~!~~!!!!?JYPB##GPPPP5YJ??7!!~^^::..       ...::^^^^7^      //
//     .YP55555555555555555555555555555555PGG5J!~^:..      ...^!JG&&B5JJ?7!~~^::..     ...::^^^~~~~~~~!?.     //
//     !P55555555555555555555555555555555G#GJ~:.                .:!5##5!~^::.     ..:::^^~~~~!!!!!!7777J~     //
//    .YPPPPPPPP555555555555555555555555B&P!:        .::::..      .^7B@5:   ...:^^^~~~!!!!!777777??????J?     //
//    ^PPPPPPPPPPPPPPPPPPP5555555555555B&P^:      .^~^^:::^~~:      :~G@5:^^~~~!!!77777????????JJJJJJJJJY:    //
//    !GPPPPPPPPPPPPPPPPPPPPPPPPPPPP55G&B~:      ^!:        .~!      :!#&J777?????JJJJJJJJJYYYYYYYYYYYYY5~    //
//    ?GGGGGGGGGGGGGGGGGGGGGGGGGGGGPPP#&Y^.     .7.           ~!     .^P@BJYYYYYYYYYYY555555555555555555P!    //
//    JP5PPPPPPPPPPPPPPPPPPPPPPPP5PP5P#@J:      :7            :7      :5&#PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPG7    //
//    ?5Y55YYYYYYYYYYYYYYYYYYJJJJJJJ??B@Y^.      !^          .7^     .^P&BPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG!    //
//    75JJJJJJJJJJJJ????????77777!!!~^J&#!:       ~~:.    .:^!:      ^7#&PPPPPPPPPPPPPPPPPPPPGGGGGGGGGGGG~    //
//    ~Y????????777777!!!!!~~~~^^::.. .5@G~:       .:^^^^~~^:       :!B&G55555555PPPPPPPPPPPPPPPPPPPPPPPP:    //
//    .J7777!!!!!~~~~~~^^^:::..    ..::~P&G7^.                    .^?B&BPP55555555555555555PPPPPPPPPPPPGJ     //
//     7?~~~~~~^^^^:::...      ..:^~~!!7?PG?!!^.                :^75B#GPPPP55555555555555555555555555PPG~     //
//     .J^^^:::....       ..::^^~!!!7?JJYYP5?JYJ7^:.      ...:~!7?5GBGGPPPPP55555555555555555555555555PY.     //
//      ~7...         ..::^~~~!!77??JYY55PGGGPGB#BG5YJ?77????7~7YGBBGGGGPPPPPPP55555555555555555555555P^      //
//       ?^      ...:^^~~~!!777??JJYY5PPGGGPP5555PGB######BGPPPBBBBGGGGGGGPPPPPPPP5555555555555555555P!       //
//       .?^ ..::^^~~~!!!77???JJYY55PPGGGGPPP55555555PPPGGGBBBGBBBBBBBGGGGGGGPPPPPPP5555555555555555P?        //
//        .?~^^~~~!!!777???JJYYY55PPGGGGPPPP55555555PPPGGGGGBBBBBBBBBBBBBGGGGGGPPPPPPPPP55555555555P?         //
//         .?7~!!!777???JJJYY555PPGGGGPPPP555555555PPPPGGGGGBBBBBBBBBBBBBBGGGGGGGPPPPPPPPPPP55555PP7          //
//           7J777???JJJYYY555PPGGGGPPPPP5555555555PPPPGGGGGBBBBBBBBBBBBBBBBGGGGGGGGPPPPPPPPP5P5PP!           //
//            ~YJ?JJJYYY5555PPGGGGGPPPPP55555555555PPPPGGGGGBBBBBBBBBBBBBBBBBGGGGGGGGGPPPPPPPPPPY^            //
//             .?5YYYY555PPPGGGPPPPPPPP55555555555PPPPPGGGGGBBBBBBBBBBBBBBBBBBBBGGGGGGGGGPPPPGP7.             //
//               ^J5555PPPGGGGGPPPPPP5555555555555PPPPPGGGGGBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGPGGJ:               //
//                 ~YPPPGGGGPPPPPPPP55555555555555PPPPPGGGGGBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGJ^                 //
//                   ^JGGGPPPPPPPP555555555555555PPPPPPGGGGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBG?:                   //
//                     :75GGPPPP5555555555555555PPPPPPPGGGGGGBBBBBBBBBBBBBBBBBBBBGBBBB5!.                     //
//                        ^?5PPP5555555555555555PPPPPPPGGGGGGBBBBBBBBBBBBBBBBBBBBBG5?^                        //
//                           ^7J5PP5555555555555PPPPPPGGGGGGGBBBBBBBBBBBBBBBBBBPY7:                           //
//                              .^7J555555555555PPPPPPPGGGGGGGBBBBBBBBBBBBG5J7^.                              //
//                                  .:^!?JY55PPPPPPPPPGGGGGGBBBBBBBGPPY?!^:                                   //
//                                        .:^~!7??JYY5555555YYJ?7~^:.                                         //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CD is ERC721Creator {
    constructor() ERC721Creator("Non-Fungible CDs", "CD") {}
}
