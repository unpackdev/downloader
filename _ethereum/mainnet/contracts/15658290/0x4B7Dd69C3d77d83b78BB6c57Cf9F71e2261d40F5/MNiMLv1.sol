
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MNiML_v1
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//                             //
//    |\/||\ |o|\/||      |    //
//    |  || \|||  ||___\/ |    //
//                             //
//                             //
//                             //
/////////////////////////////////


contract MNiMLv1 is ERC721Creator {
    constructor() ERC721Creator("MNiML_v1", "MNiMLv1") {}
}
