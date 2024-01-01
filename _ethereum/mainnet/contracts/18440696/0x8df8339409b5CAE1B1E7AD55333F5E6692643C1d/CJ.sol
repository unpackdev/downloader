// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CARTIST JOURNEY
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    CARTIST JOURNEY    //
//                       //
//                       //
///////////////////////////


contract CJ is ERC721Creator {
    constructor() ERC721Creator("CARTIST JOURNEY", "CJ") {}
}
