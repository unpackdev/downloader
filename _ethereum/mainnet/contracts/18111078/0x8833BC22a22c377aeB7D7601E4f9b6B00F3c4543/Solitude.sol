// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Solitude
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//    Solitude    //
//                //
//                //
////////////////////


contract Solitude is ERC721Creator {
    constructor() ERC721Creator("Solitude", "Solitude") {}
}
