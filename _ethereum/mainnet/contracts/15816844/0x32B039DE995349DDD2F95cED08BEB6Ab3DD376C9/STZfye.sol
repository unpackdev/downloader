
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: You are on fire
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                  .:                                                        //
//                                                  .J?.                                                      //
//                                 .:                ^PP7                                                     //
//                                 !7                 Y5PJ.                                                   //
//                                .G?                 ?PJP5:                                                  //
//                                .BG:                ?PJJPY.      :                                          //
//                                 JBY.         ^:   .P5JJJG!      7J:                                        //
//                                 ^GPY:       ?P:  :5PJJJJG7      :PG?.                                      //
//                            ^^   :GY5P7.    :GG~.!P5JJJJ55::     .YP55:    :^                               //
//            :7.             :55: 7PJJY55~ ^.:P5555YJJJJ55~Y!     .55J55.   .JJ:               :J^           //
//            JB!              ~BPJPYJJJJ5P.~P~7PYJJJJJJYGY5GJ     !PYJJG! !: :5P~             :5B?           //
//           ~G5P~             Y5P#YJJJJYP7 !BP:7PJJJJJJ5#BYJP~   7PYJJYG~:GY. YPP. :.        ^P5YP:          //
//           YGJYP~           ?PJYYJJJJ5Y~~JPJP? Y5JJJJJJ55JJP7 ^5PYJJJPY!PYY7.P5PJYY.       7PYJJG?          //
//          :GPJJYP!         !GJJJJJJJPGJY5YJJ5J Y5JJJJJJJJJ57..55JJJJ5B55YJ5Y~PYJYG!      .YPYJJJPY.         //
//          ~B5JJJYPY:       JPJYJJJJYBGYJJJJJPJJPJJJJJJJJJJP!YJP5JJJJJJJJJYPJ55JJPY.     ~P5JJJJJ5P.         //
//          ?BYJJJJJ5P?:     ~GYJJJJJYYJJJJJJ5BPYJJJJJJJJJJJ55Y5PYJJJJJJJJJ5G5YJYPY:    :JPYJJJJJJ5G:         //
//         .Y#5JJJJJJY55?^    ^Y55YJJJJJJJJJJYJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJY55Y!    .?P5JJJJJJJJ5G:         //
//         :55PJJJJJJJJJ555?^.  :!J555YYJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJYY555J!:    :?55YJJJJJJJJJ55.         //
//         :5^55JJJJJJJJJJY555J7^. .^!?JY555555YYYYYYYJJJJJJJJYYYYYY5555Y?!^.    :!Y55JJJJJJJJJJJJPY.         //
//         :P:~GYJJJJJJJJJJJJJY555YJ!~:...:^^~!7?JJYYYYY5555YYYYJJ?7~^:.    .^!?Y55YJJJJJJJJJJJJJY#?          //
//         :P~ !GYJJJJJJJJJJJJJJJJYY5555Y?77~~^^:...:::::::::::....:^^~!7?JY555YYJJJJJJJJJJJJJJJYGG~          //
//         .57  ~P5JJJJJJJJJJJJJYYYYYJJYJ7J5555555YYYYYYYYYYYYYYYY55YYY55YYJ??JYJJJJJJJJJJJJJJYPY!J:          //
//          J?   :JPYJJJJJJJJJJY?77??JYJ!!YYYJJJJJJJJYYYYYYYYYJJJJJJ??!7JJ?!!?YYJJJJJJJJJJJY55Y~ ??           //
//          !J.    ^J55YJJJJJJYYJ7!~~~!!^^!7?JJJJJJJJJJJJJJJJJJJJJJYJJ?7!!!7?YYJJJJJJJJYY5PY7:  ^Y:           //
//          .Y~      :!J5P5YYJJJYYYJJ?!^^~!~!!JYJJJJJJJJJJJJJJJJJJJJYJ?7!!7!7?JYJJJY555Y7!P:    J7            //
//           7J         YB7?Y555YYYJYJ!~?JYJJYYJJJJJJJJJJJJJJJJJJJJYJ7!7??J?????YPP?!^.  .5:   ~Y             //
//           .Y!       ?!!7  :^!?JY55J7?5YYYJJJJJJJJJJJJJJJJJJJJJJJYJ??JY5555J7Y7^J~     ^Y.  .5^             //
//            :5:     ?7 .J~      ..:^~!?JJ5PP5555555555555555555PPYJJJ?!~^..  J! .?!    ~J   J?              //
//             ^5:   ?7   :Y:             ^J^Y^.::::^^^^^^^^:::.J7?7           Y^   J7   77  !J.              //
//              ~Y^ 77     !J            .J^ ^Y                ^J. 7?         :Y:    J!  ?? ~Y:               //
//               :JY7       ?7           ?!   77              .Y~   !?.       ~J.     ?! J!^Y:                //
//                .J?:      .Y^         7?    .J^             7?     !J       !7       ?!7PJ:                 //
//                  ^J7.     :Y.       ~J      ^5:           ~5.      !J      ?7        ?G?.                  //
//                    ~J!:    ~J      ^J.       ~?          :G^        !J.    J!      :7?^                    //
//                      ~J7:   7?    ^J:         7!         5?          ~J.  .Y~    ^7J~                      //
//                        ^7?!: 77  ^Y:           7!       75.           ^J^ :J^ :!?7^                        //
//                          .~7775!~J.             ?~     ^P^             .?~~Y?77~.                          //
//                             .^7YP!:.            .?^   .57            .:^!Y?!^.                             //
//                                 .~7?7!^:.        .J^  7J       ..:^!777~:                                  //
//                                     .^~!7777~~^^:.^5~!J^^^^~!777!!~:.                                      //
//                                           .::^~!!!~!7!!!!~^^:..                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract STZfye is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
