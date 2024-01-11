
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Crown of the Kings Editions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//         * * * *          //
//    * * * \|O|/ * * *     //
//     \o\o\o|O|o/o/o/      //
//     (<><><>O<><><>)      //
//     '============='      //
//    CROWN OF THE KINGS    //
//                          //
//                          //
//////////////////////////////


contract CROWN is ERC721Creator {
    constructor() ERC721Creator("Crown of the Kings Editions", "CROWN") {}
}
