
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PICKLE
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    PICKLE #26426    //
//                     //
//                     //
/////////////////////////


contract PKL is ERC721Creator {
    constructor() ERC721Creator("PICKLE", "PKL") {}
}
