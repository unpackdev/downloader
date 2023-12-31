// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ZM Simple
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    With love, ZM    //
//                     //
//                     //
/////////////////////////


contract ZMSMPL is ERC721Creator {
    constructor() ERC721Creator("ZM Simple", "ZMSMPL") {}
}
