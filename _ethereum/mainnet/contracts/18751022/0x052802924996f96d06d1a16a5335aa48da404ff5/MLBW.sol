// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Modern Life in Black & White
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//           ....                        _                                                          //
//       .xH888888Hx.                   u                                                           //
//     .H8888888888888:                88Nu.   u.         u.      u.    u.                          //
//     888*"""?""*88888X        .u    '88888.o888c  ...ue888b   x@88k u@88c.                        //
//    'f     d8x.   ^%88k    ud8888.   ^8888  8888  888R Y888r ^"8888""8888"                        //
//    '>    <88888X   '?8  :888'8888.   8888  8888  888R I888>   8888  888R                         //
//     `:..:`888888>    8> d888 '88%"   8888  8888  888R I888>   8888  888R                         //
//            `"*88     X  8888.+"      8888  8888  888R I888>   8888  888R                         //
//       .xHHhx.."      !  8888L       .8888b.888P u8888cJ888    8888  888R                         //
//      X88888888hx. ..!   '8888c. .+   ^Y8888*""   "*888*P"    "*88*" 8888"                        //
//     !   "*888888888"     "88888%       `Y"         'Y"         ""   'Y"                          //
//            ^"***"`         "YP'               ..                                                 //
//                  ..                     x .d88"                                                  //
//                 @L                       5888R                                                   //
//          u     9888i   .dL        u      '888R         u                                         //
//       us888u.  `Y888k:*888.    us888u.    888R      us888u.                                      //
//    .@88 "8888"   888E  888I .@88 "8888"   888R   .@88 "8888"                                     //
//    9888  9888    888E  888I 9888  9888    888R   9888  9888                                      //
//    9888  9888    888E  888I 9888  9888    888R   9888  9888                                      //
//    9888  9888    888E  888I 9888  9888    888R   9888  9888                                      //
//    9888  9888   x888N><888' 9888  9888   .888B . 9888  9888                                      //
//    "888*""888"   "88"  888  "888*""888"  ^*888%  "888*""888"                                     //
//     ^Y"   ^Y'          88F   ^Y"   ^Y'     "%     ^Y"   ^Y'                                      //
//                       98"                                                                        //
//                     ./"                                                                          //
//        ....      ..~`                                s                                           //
//      +^""888h. ~"888h     .uef^"                    :8                                           //
//     8X.  ?8888X  8888f  :d88E              u.      .88           u.                              //
//    '888x  8888X  8888~  `888E        ...ue888b    :888ooo  ...ue888b                             //
//    '88888 8888X   "88x:  888E .z8k   888R Y888r -*8888888  888R Y888r                            //
//     `8888 8888X  X88x.   888E~?888L  888R I888>   8888     888R I888>                            //
//       `*` 8888X '88888X  888E  888E  888R I888>   8888     888R I888>                            //
//      ~`...8888X  "88888  888E  888E  888R I888>   8888     888R I888>                            //
//       x8888888X.   `%8"  888E  888E u8888cJ888   .8888Lu= u8888cJ888                             //
//      '%"*8888888h.   "   888E  888E  "*888*P"    ^%888*    "*888*P"                              //
//      ~    888888888!`   m888N= 888>    'Y"         'Y"       'Y"                                 //
//           X888^"""       `Y"   888                                                               //
//           `88f                J88"                                                               //
//            88                 @%                                                                 //
//            ""               :"                                                                   //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                      A collection of photos exploring black and white photography.               //
//                             This is Modern Life as I see it, and the depths                      //
//                                      of oneself reflecting through time.                         //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract MLBW is ERC721Creator {
    constructor() ERC721Creator("Modern Life in Black & White", "MLBW") {}
}
