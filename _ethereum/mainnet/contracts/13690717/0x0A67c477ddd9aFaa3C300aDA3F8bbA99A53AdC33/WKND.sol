
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: yung wknd
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    it's the wknd    //
//                     //
//                     //
/////////////////////////


contract WKND is ERC721Creator {
    constructor() ERC721Creator("yung wknd", "WKND") {}
}
