
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Carbon 2022 Summer Rally
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                             .~~                            //
//                                                                            .J7?!                           //
//                                                                           .?7!!J.                          //
//                                                                          .?7!!!?7                          //
//                                                                         ^?7!7777Y:                         //
//                                                                       .7?!!77777J7                         //
//                                                                      ~?7!777777??Y                         //
//                                                                    ^7?!!777777???Y^                        //
//                                                                  ^7?7!777777?????Y7                        //
//                                                               .~7?7!777777???????JJ                        //
//                                                             :!?7!!777777???????JJJ5.                       //
//                                                          :!777!!7777777??????JJJJJ5:                       //
//                                                      .:!77!!!!!777777???????JJJJJJ5^                       //
//                                                   .^!77!!!!!!777777???????JJJJJJYY5~                       //
//                                                .^!77!!!!!!!777777???????JJJJJJJYYY5!                       //
//                                             .^!7!~~~!!77777777777??JJJJJJJJJJYYYYYP~                       //
//                                          .~!7!~~!777!~^^::::::::::..:^!?YYJYYYYYYYP~                       //
//                                       :~!!!~~!7!~::::^~!77????JJJJJ?7!^ .7YYYYYY55P^                       //
//                                    .~!!~~~!7~:.:^!77?777777??????JJJJYYY~ :Y5Y5555P.                       //
//                                 .^!!~^~!7~:.:!77777777777???????JJJJJJYY57 :55555P5                        //
//                               :~!!~^~77^ :!77!!!!777777???????JJJJJJYYYYY5. J5555PJ                        //
//                             ^!!~^^^!7^ :77!!!!!7777777??????JJJJJJJYYYYYY5. YP55PG~                        //
//                           ^!!^^^^~?~ :77!!!!!7777777??????JJJJJJJYYYYYYYP7 :P5PPPP.                        //
//                         ^7!^^^^^!?: !?!!!!!!777777???????JJJJJJYYYYYYY55Y :5PPPPGJ                         //
//                       ^7!^^^^~~!?  ?7!!!!!777777???????JJJJJJYYYYYYY555555PPPPPPG^                         //
//                     :7!^^^^~~~~J. ?7!!!!7777777??????JJJJJJJYYYYYY5555555PPPPPPGY                          //
//                   .!!^^^^^~~~~77 ^J!!!7777777???????JJJJJJYYYYYYY555555PPPPPPGGG^                          //
//                  ^7~^^^^~~~~~~7? :J77777777????JJJJJYYYYYYYYYYY555555PPPPPPPGGBJ                           //
//                 !7^^^^~~~~~~~!!?! .!77?????777!!~~^^^^^^~~!7JY555555PPPPPPGGGGP.                           //
//               .7!^^^~~~~~~~!!!!!??~::::::::::^^~~!!777777!~^:.:?PPPPPPPPGGGGGB~                            //
//              .?~^^^~~~~~~~!!!!!777???????JJJJJJYYYYYYYY555555Y^ ^PPPPPPGGGGGB7                             //
//             .?~^^~~~~~~!!77777777777??J????JJJJJJYYYYYYY55555PG~ ~GPPGGGGGGBJ                              //
//             ?~^~~~~~!77!~^:::::::::::.^7YJJJJJJJYYYYYY5555555PPY .PGGGGGGGBY                               //
//            !7^~~~!77~:.:^~!77??????JJ?  JYJJJJYYYYYYY555555PPPPY  PGGGGGBBY.                               //
//           .J~~~!7~..^!7777777777??JJ7: ^YJJJYYYYYYY555555PPPPPG! ^GGGGBB#Y                                 //
//           ~7~~7!..!?77!!77777???JJ~. ^?YJJJYYYYYY5555555PPPPPGJ  5BGGBBB?                                  //
//           7!~?~ ^?7!!7777777??JJ~  ~JYYJJYYYYYY5555555PPPPPGG?  YBGBB#G~                                   //
//           ?!!? .J!!!777777???J!  ~JYJJJYYYYYYY555555PPPPPGG5~ :5BBBBBJ.                                    //
//           ?!?! ~J!777777???JJ: .?YJJJYYYYYYY555555PPPPGGPY~ .?GBBB#5^                                      //
//           !77? :J777777???J?  :YYJJJYYYYYY555555PPPGGPY!. ^JGBBB#P!                                        //
//           :J!J~ :????????J?  :YJJJYYYYYY5555PPPPP5J!^..^?5BBBBBP7.                                         //
//            !J!?7: :!??JJJY  .YYYYYY5555555YJ?7~^..:~7YPGBBBBBP!.        :~7JYYYJ7^                         //
//             7J7?J?~:..:^~:  :?77777!!~^::..::~!?Y5GGGGGGBBGY~       :!JPB##BGGB#&#G?.                      //
//              !J?7??JJ?77^  .^^^^^^~~!77?JY5PPGGGGGGGGBBG57:      :7YGBBPY!^.. .:!P&&G:                     //
//               :?J????JJ5~  75Y5555555PPPPPPPPPPGGGBBPY!:      ^7YGBG5?^.          Y#&P                     //
//                 ~?JJJJJ5.  YYYYY555555PPPPPGGGGGPY7^.     .^?YPGG57^              ~##B:                    //
//                   ^7JY5?  .5YY55555PPPPGGPP5Y?~:.     .^!J5PPPY7:      .:.        J##G                     //
//                     .^~.  .5555555YYJ?7!^:.     .:^~7JY5P5Y?~:        .GBG~     :?#&#!                     //
//                            !?7!~^^:.....::^~!!7?JY555YJ7~:             7B##PYJYP#&#P~                      //
//                           .J!77777?????JJJJYYYJJ?7!~:.                  :75GBBBG5?^                        //
//                            .:^^~~~!!!!!!~~~^::.                             ...                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SMMR is ERC721Creator {
    constructor() ERC721Creator("Carbon 2022 Summer Rally", "SMMR") {}
}
