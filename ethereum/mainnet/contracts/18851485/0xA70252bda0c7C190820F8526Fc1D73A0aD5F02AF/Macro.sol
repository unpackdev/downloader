// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Macro Photography
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//    Renee Campbell Macro Photography    //
//                                        //
//                                        //
////////////////////////////////////////////


contract Macro is ERC721Creator {
    constructor() ERC721Creator("Macro Photography", "Macro") {}
}
