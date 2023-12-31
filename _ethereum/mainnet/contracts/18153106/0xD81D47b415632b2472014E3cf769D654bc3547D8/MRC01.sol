// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MRC 0NCHA1N
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    MRC 0NCHA1N    //
//                   //
//                   //
///////////////////////


contract MRC01 is ERC721Creator {
    constructor() ERC721Creator("MRC 0NCHA1N", "MRC01") {}
}
