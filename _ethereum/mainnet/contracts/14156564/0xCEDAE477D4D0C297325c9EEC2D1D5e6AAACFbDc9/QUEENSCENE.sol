
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Queen Scenes
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//            *            //
//          * | *          //
//         * \|/ *         //
//    * * * \|O|/ * * *    //
//     \o\o\o|O|o/o/o/     //
//     (<><><>O<><><>)     //
//      '==========='      //
//                         //
//                         //
/////////////////////////////


contract QUEENSCENE is ERC721Creator {
    constructor() ERC721Creator("Queen Scenes", "QUEENSCENE") {}
}
