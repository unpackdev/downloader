
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: EM0
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//                    --- //.-"//                     //
//                   /  .//-  //                      //
//                   \  //   //                       //
//             .-""-.,:// _-//<                , /    //
//            /    _; x / )x|               ' '       //
//            \  ; / `  `"  '\.             `         //
//     ,       '.-| ;-.____, | em0         .,         //
//     ,            \ `._~_/ /             /"/        //
//    ,.           /`-.__.-'\`-._     ,",' ;          //
//    \"\         / /|  em0   \._ `-._; /  ./-.       //
//     ; ';,     / / |    ’___\ `-.,( /  //.-'        //
//    :\  \\;_.-" ;  |.-"``    `\    /-. /.-'         //
//     :\  .\),.-'  /      }{    |   '..'             //
//       \ .-\      |          , /                    //
//        '..'      ;'        , /                     //
//                 ( __ `;--;'__`)                    //
//     xxxxxxxxxxxxx`//'`xxxx`||`xxxxxxxxxxxxxxx      //
//     xxxxxxxxxxxxx//xxxxxxxx||xxxxxxxxxxxxxxxx      //
//     xxxx.-"-._,(__)xxxxxx.(__).-""-.xxxxxxxxx      //
//     xxx/          \xxxxx/           \xxxxxxxx      //
//     xxx\          /xxxxx\           /xxxxxxxx      //
//     xxxx`'--=="--`xxxxxxx`--""==--'`xxxxxxxxx      //
//     xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx      //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract EM0 is ERC721Creator {
    constructor() ERC721Creator("EM0", "EM0") {}
}
