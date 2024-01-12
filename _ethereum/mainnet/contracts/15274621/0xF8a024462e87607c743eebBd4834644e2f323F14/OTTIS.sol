
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Purple Valley by Ottis
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                           .      7?^    :77.                                                                   //
//                                         ~7?~.   ~YYY?^:!Y55J^::^?77!.                                                          //
//                                         ^Y5YJ?77Y5Y5555Y55555YYYY55Y?:.  ....:                                                 //
//                                      ^7~!Y555555555555555555555Y5Y5YYY?^^?YYJJ?J!                                              //
//                               ^7!^^::?555Y55555555PP5555P5555Y5555555Y55Y55555Y!.                                              //
//                              :J555YYJYY55555555555PPPPP5P55PPP555PPPP55PP5555Y7..:.                                            //
//                              .!55555YY55555PPPPPPPPPPPP555PP5P555PP55555PPPPP5YYYYJ??7.                                        //
//                               .?555555PPPPPPP5PGGPPPP55P5P55PPPPP5PPPPPPPPPPPPPP5555J~                                         //
//                            ^^.^7Y555PPPPPPPPPPGGPPPP55Y5P5PPPPPPPPPPPP5PPP5555P55555J~^!!!^                                    //
//                            ~Y55555PPPPGGGGPPGPPP5PPPP5PPPPPPPPPGGGPPP55555P5PPPP5555555P55Y?77!~^:                             //
//                             ^J555PPGGGGGPPPPPPPPPPPP555PPPGPPGP5YPPPPPPP5PPPPPP555PPP55Y!~?5555YJ7.                            //
//                           ..:^J5PPPPPPPGGGGPPGGGPPYJ5555PPPPPPP5YPPGGGGGPPPPPPPPPP5?5555Y55P555!.                              //
//                         :?JY55555PPPPPGGGGPPGPPPP555PPPPPP5PPPGGGGGGGGGPPGGPGPP555PPP555PP5555?!~.                             //
//                     :J?7?55555PPPPGPPGPGGGGGGPGPPPPPPPPPPPGGPPGGGPPPPPPPGGGPPPP5555555PPP5YYY555Y~                             //
//                     .!Y555555PPPGGGGGGGGGGPPPPPPPPPGGGGGGGGGPPPPPPPPP5PPPPGGGGPPPPPPPPPPP55YYJ!^:.                             //
//                .. ^~!7Y555Y555PPPGPPPPPPP5555PPPPP5PPPPPGGGGPPPPPPGGGGGGGGPPP5555PPPPPG55PPP57~:                               //
//               :JJJ5PPP555Y555PPP5PPPPPPPPP555PPPPPPGPPP5PGGGGGGPP5PPGGGGPPPPPPPPPPPP55P57!?Y5555J!                             //
//          ^7?JJY55PPPPGPPPPPPPPPP5PPPPPGP555PPPPPPPGGGGPPGGGGGGPGP5PGGGPPPPPGGGPPPPPPPP557:.:^^~Y55!^7JJ!.                      //
//         ^J555PPPPPPPPGGPPPPPPPPPGGGGPPPPPGGGGGGGGGPPPPPPPPGGPPP5PPGGGGGPPGGGPGGGGPPPPP5555Y5555555YYY5J!.                      //
//          .:::^~YP5PPPPY5GGGGPPGGGGGGGGGPPPGGGGGGGGGGGGGPPPGGPPPPGPPPPGGG5?J?~~7?P5PPPPPPPP55P5PP5Y555YJ??7~.                   //
//               .!?YPPGPGGGGGGGGGGGGGGGGGGGG55G55PGGPGGGGG55GGPPPGGGPPPPPPPJY5Y?JJP5PP55PP5555PP55555PPPPY7!^                    //
//                 ~Y55PPPG5?J5GGGGGGGGGGGGGGP5GJ^JGPPPGGPP5PPPGGGGPPP55PP55PP55555PP5PPPPP5PPPPPPPPPPPPP5Y?~.                    //
//                   ~~!5PPPYJJP55PPGGGGPPGGPPGGG!.PPPPGGPPGGGGGGGGGGGPPPPPPPPP555PGGPGPPPPPPP55PGGGPPPPPPP5?.                    //
//                   7J!^^~Y5555Y55Y5PPPPG5GGGGGGPJP5PPGGPPGGGGPGGGGPPGPPGGGPPPPPPPPP5PPPY75PP??PPPPPPP55Y?:                      //
//                        !55P5PPPPPPPP55PPGGGPPPGGGPPGGGGGGGGGGGGGGGGGGGGGGGGGGPPPGPPPPPPJY55555PPPPP55J~:                       //
//                   .7J??5PPPPPPPGGPPPPPPPPPGGGGGGGP5PPPPPPPGGGGGGGPPPPP55PPGPPPGPPPGGPPPP5PPPPPPGGP55555J7J?:                   //
//        :::~~^:..^!J5PPPPPPPPPPGGGGPPGGPPPPPPPPPPGPPPPPGPPPPGGGPPPPPGPPPPPPPGGY?PPPP5555555PPPPPPPPP5PP55555J~.                 //
//    .:!7YYJ5PP55YYP5J5PPPP55PGGGGGGGGGGGGGPPPPP5PGPGGGGGP5PGGGGGPPGGGGGGGGPPPG5YGGPPPPPP5555PPPPPPPP55PP555555!                 //
//    ~?JY555Y5PPPPPP7!Y5PGJ:~JGGGGGGPPGGGGPGPPPPPPPPPPPGPPPGGGPGGGPGGGGGGGPPPPPPGPPPPGGGGGPP555PPGGPPP5PPP5555557.               //
//       .:?55YYP5J?YPPPPPPYYPPPGGGGGGGGGPPPGGPGGGGGGPPGP55PPGGGGGPP5GGGPPGPGGGGGGGGGPGGGPPPGGGPPPPPPP55555YYY?~^^                //
//     .^~?5PP5555J?YPPPGPPPPPPGGGGGGGGGGGPPGGGGGGGGY5PGGGGGGGGPGGGPPPPP55PPG5YPGGGGGGGGGGGGGGGGGGGGGGPPP55YJ?7!!7!.              //
//    7Y55PPPPPPPPGGPPG5YYPPPPPPGGGGGGGGGGGGGPGGPGP5?PPPGGGGPPPGGGGGPPPPP5PGGY75GPGGGGGGGGGGPPPGGGGPPPPPPPP55555555J!!^:::        //
//    ~:..J5PP55PP?~::^. .JPPPPPPPPGGGGGGGGGGPGGGPPPGGGGPPGGPPPGGGGPGGGGGGGGGGGGGGGGGGGGPGGGGGGPPPPP5555PPP5PPPP5P55PPP555J^      //
//      ^?Y?75P5?^     .~!JPPPPPGGGGGGGGPGGG?:7PPJ?PGGGPP55PPGGGGGGGGGGGGGGGGGGGGPPGGGGGPP5PPPGGGPPPPPPPPPPPPGPPPPPP5PY!7Y55?:    //
//    .^~?557!!:       ^5PGG5PPGGGGGGGGGGGGGPY5PGGGPGGGPGGYYGGGGGGGGGPPPGGBPYY!^YJJGGJ!??!~?GGGGGGGPPPPPPGGGGPPP55YY5J:  .:::.    //
//       :7!.       .!JYP5?!755J??PGGGGGGPGGGGGGGGGGP5PPPG5GGP55PPGP555PP5?^   !PP5PGPPGPGPPGGGGGGGGPPPPGPJ!7^::..  .             //
//                  ^Y5?^:~~7YY!~7PPPPGGGGPY5GGGGGGGGGGPGGPPPPPPP5?~7P5J7~:.^JYPGGGP5Y55P5J!~!~^?JYGPGGGGY:                       //
//                  .:. .7Y555PPGGGGPGGGGGP??JPGPPPPGGGGGGPPPPGGB? :7^:. ^JJ7~^~!!~^   ..         .:.!JJY55?:                     //
//                     :YPPGG5PGPPGGGGGGGGGGGPP5PP5555PPGGGPGGGGGYJ?. .~?7:                              :~^                      //
//                     :7??!!:7JJYY?!JPPYJ!~7?5PPGPP555YPG5JGGGGGP:.?J7~:                                                         //
//                                    :.  ~YP5J???!^~~~7JBG5GBBGGPY?^.                                                            //
//                                       :Y5?~          :?GBBBBBB5:                                                               //
//                                        ..              ~BBBBBB?                                                                //
//                                                         PBBBBB7                                                                //
//                                                         5BBBBG^                                                                //
//                                                         JBBBB5                                                                 //
//                                                         7BBBBJ                                                                 //
//                                                         JBBBBP.                                                                //
//                                                         YBBBBB~                                                                //
//                                                        ~GBBBBBJ                                                                //
//                                                        7BBBBBB5                                                                //
//                                                        JBBBBBG5.                                                               //
//                                                       .PBBBBBBG:                                                               //
//                                                       .?JJJJJJ?:                                                               //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract OTTIS is ERC721Creator {
    constructor() ERC721Creator("Purple Valley by Ottis", "OTTIS") {}
}
