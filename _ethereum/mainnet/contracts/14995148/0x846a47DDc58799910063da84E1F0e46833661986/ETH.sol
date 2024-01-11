
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mi contrato
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                             .~JY^                                                          //
//                                           :?G#B5^                                                          //
//                                         ~YB#BPJ?!. .^^:                                                    //
//                                      .7P####BB###55G##BGP5?????.                                           //
//                              .::.   .5################BBPP5!7GG.                                           //
//                            :JGB#G~   ~5B############BGBBG##B##BJ??. .                                      //
//                           .P&###&7 :?PB####BBB#####GPPPYG####BY???JPGY~~!:                                 //
//                           .YBBG5!~5B#####BP555PB#PJYYPY^?G###GYPB#######&B7                                //
//                            !Y?:  Y#######BP5555J??YJ?BY!!!J5GG##########BG?                                //
//                           .5#B!:5B########BPY?!?J??!YY?7!!!5B##########GJ77.     .^~^.                     //
//                            .^: !B#####B##57!!!Y?!Y77PJ!7!!?######GG#####B57   :!YG#&G^                     //
//                             .!5BBG#B##GY7!~~?PJ!Y5YYPJ!77!Y######Y~G##BGPJ~!?5B&#GY!:                      //
//                           ^JG###5~GGP7^~!!~YPY?75YYY55!!7!?#####B#B#########&&BJ^                          //
//                          ~B####BBG##J::~!~YGYY!75YYYYYJ!!!!P###BG###########P?: .^^.                       //
//                          .?G#######BP^~!~YBPY?!?5YYYYY5?!!!7P#BB###########?    ~YJ^                       //
//                          ^G####BGPPPG7^~YG55J7!?55YYYYY5J7!!YG55PB##B######G~  ~?Y?:                       //
//                          .J###BG5YY5PP:!PYYJ?!!!P55YYYYY5PY7J5YY5G########G?. Y####G:                      //
//                          .5####BGPPGBG775YY5YJ7!YPP55YYYYY555GPGGB#BB#####5?: JGB#B?                       //
//                         ~PB######BBB#BG?YYY5PP5?7PP555YYYYYYYY5PBB#GG######G?   :^:                        //
//                         ?&##B5?!75B####PYYYJYPP5J?PP555YYYYYYYJP#######BB###J                              //
//                         ^JJ!:^75B######BYYYYYP5PPY75PPPP555Y5YPGG&#########Y                               //
//                            ^P#&#########GYYYY55PPP?!YPPP5PPPYPGPPB#########?                               //
//                            ^JJJB########BGYYY55PPP5!!J5PPPP5PP55PPG#####BP?~~.                             //
//                               .!?Y555Y?!!PPYYY55PPP?!!!?Y555PYY5Y?!JGB##P5GBY.                             //
//                                      .!5B##YYY5YYPPY!!!!!!JPYYYJ!!!!YPG###P: ..                            //
//                                    ~YB######5Y55YPP57!!!!!PYYY?!!!7PB##GY7^~YGBJ                           //
//                                 :7P#&#G#B####PY55PPP?!!!!555Y7!!!JB###B5PGB&#GJ:                           //
//                                7B&&#GB##JG####G55PP5?7!!YPYJ!!!75B########BY~.                             //
//                                ^JY?^~B##BB#####B5PP5JJ?JG5J!!!?G#BB####BP7:                                //
//                                   :YB###B57YB###G5PP5YYPBY~!!YB#######BY.                                  //
//                                   ?BBPJ!~?PB#####P5P555BP!~!5#B?B#####5~                                   //
//                                    .:^75B###B####PPGP55#J~!P#PB5B####B~                                    //
//                                   ^?P#&&#BBGB####PGPP5BG~~P##GB#####J:                                     //
//                                .!PB&#B57^:..5##BBBGGP5B5~5BGB######B^                                      //
//                               .Y##GJ~.     ?###BB##BGPBJJG555PB###G!                                       //
//                                .^:         ~YYJ?YB###BBPBP555PB##Y:                                        //
//                                               .!5B####BB#BBBB###?.                                         //
//                                              ^G&&#BPJ?G###GG##B?                                           //
//                                              :7J?!:   ~7!^..^~:                                            //
//          ..  .      .:.                                                                                    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ETH is ERC721Creator {
    constructor() ERC721Creator("Mi contrato", "ETH") {}
}
