
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Reechew.mintedlab
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    reechew.mintedlab    //
//                         //
//                         //
/////////////////////////////


contract Reechew is ERC721Creator {
    constructor() ERC721Creator("Reechew.mintedlab", "Reechew") {}
}
