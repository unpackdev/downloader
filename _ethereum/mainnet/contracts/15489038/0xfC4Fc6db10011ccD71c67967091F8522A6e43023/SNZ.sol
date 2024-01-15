
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SNEEZE
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//                                   //
//                                   //
//      ___ _  _ ___ ___ _______     //
//     / __| \| | __| __|_  / __|    //
//     \__ \ .` | _|| _| / /| _|     //
//     |___/_|\_|___|___/___|___|    //
//                                   //
//                                   //
//                                   //
//                                   //
//                                   //
///////////////////////////////////////


contract SNZ is ERC721Creator {
    constructor() ERC721Creator("SNEEZE", "SNZ") {}
}
