// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GMTC I
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    --------GM--------    //
//    ---Time-Company---    //
//                          //
//                          //
//////////////////////////////


contract GMTC is ERC721Creator {
    constructor() ERC721Creator("GMTC I", "GMTC") {}
}
