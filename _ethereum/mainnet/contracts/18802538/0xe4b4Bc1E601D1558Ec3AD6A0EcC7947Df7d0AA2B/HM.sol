// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Let's Marry Overseas!
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//             /"\             //
//         /"\|\./|/"\         //
//        |\./|   |\./|        //
//        |   |   |   |        //
//        |   |>~<|   |/"\     //
//        |>~<|   |>~<|\./|    //
//        |   |   |   |   |    //
//    /~T\|   |   =[@]=   |    //
//    |_/ |   |   |   |   |    //
//    |   | ~   ~   ~ |   |    //
//    |~< |             ~ |    //
//    |   '               |    //
//    \                   |    //
//     \                 /     //
//      \               /      //
//       \.            /       //
//         |          |        //
//         |          |        //
//                             //
//                             //
/////////////////////////////////


contract HM is ERC721Creator {
    constructor() ERC721Creator("Let's Marry Overseas!", "HM") {}
}
