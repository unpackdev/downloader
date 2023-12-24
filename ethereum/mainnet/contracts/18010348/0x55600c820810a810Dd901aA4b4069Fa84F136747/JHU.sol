// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Johns Hopkins Psychedelic Research
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//            __.....__            //
//         .'" _  o    "`.         //
//       .' O (_)     () o`.       //
//      .           O       .      //
//     . ()   o__...__    O  .     //
//    . _.--"""       """--._ .    //
//    :"                     ";    //
//     `-.__    :   :    __.-'     //
//          """-:   :-"""          //
//             J     H             //
//             :     :             //
//            J       H            //
//            :       :            //
//            `.Dölen.'            //
//                                 //
//                                 //
/////////////////////////////////////


contract JHU is ERC1155Creator {
    constructor() ERC1155Creator("Johns Hopkins Psychedelic Research", "JHU") {}
}
