// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: World & Color
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//                  _oo##'9MMHb':'-,o_                  //
//              .og":HH$' ""'  "' -\7*R&o_              //
//           .oHMMMHMO#9:          "\bMMMMHo.           //
//          dMMMMMM*""'`'           .oHM"H9MM?.         //
//        ,MMMMMM'                   "HLbd<|?&H\        //
//       JMMH#H'                     |MMMMM#b>bHb       //
//      :MH  ."\                   `|MMMMMMMMMMMM&      //
//     .:M:d-"|:b..                 9MMMMMMMMMMMMM+     //
//    :  "*H|      -                &MMMMMMMOMMMMMH:    //
//    .    `LvdHH#d?                `?MMMMMMMMMMMMMb    //
//    :      SMMMMMMH#b               `"*"'"#HMMMMMM    //
//    .   . ,MMMMMMMMMMb\.                   {MMMMMH    //
//    -     |MMMMMMMMMMMMMMHb,               `MMMMM|    //
//    :      |MMMMMMMMMMMMMMH'                &MMMM,    //
//    -       `#MMMMMMMMMMMM                 |MMMM6-    //
//     :        `MMMMMMMMMM+                 ]MMMT/     //
//      .       `MMMMMMMP"                   HMM*`      //
//       -       |MMMMMH'                   ,M#'-       //
//        '.     :MMMH|                       .-        //
//          .     |MM                        -          //
//           ` .   `#?..    .             ..'           //
//               -.     _.             .-               //
//                  '-|.#So__,,ob=~~-''                 //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract WAC is ERC721Creator {
    constructor() ERC721Creator("World & Color", "WAC") {}
}
