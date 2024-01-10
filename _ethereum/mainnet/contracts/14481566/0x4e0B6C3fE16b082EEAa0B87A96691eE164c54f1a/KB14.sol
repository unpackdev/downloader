
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KattyBoop
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    KattyBoop14    //
//                   //
//                   //
///////////////////////


contract KB14 is ERC721Creator {
    constructor() ERC721Creator("KattyBoop", "KB14") {}
}
