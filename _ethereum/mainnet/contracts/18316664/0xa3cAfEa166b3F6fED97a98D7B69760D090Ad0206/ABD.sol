// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ABDOAD
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////
//              //
//              //
//    ABDOAD    //
//              //
//              //
//////////////////


contract ABD is ERC721Creator {
    constructor() ERC721Creator("ABDOAD", "ABD") {}
}
