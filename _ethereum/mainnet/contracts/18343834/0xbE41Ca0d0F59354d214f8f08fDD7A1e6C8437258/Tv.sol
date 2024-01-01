// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Television
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////
//          //
//          //
//    📺    //
//          //
//          //
//////////////


contract Tv is ERC721Creator {
    constructor() ERC721Creator("Television", "Tv") {}
}
