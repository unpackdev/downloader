
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: sunset
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    MIR    //
//           //
//           //
///////////////


contract MIR is ERC721Creator {
    constructor() ERC721Creator("sunset", "MIR") {}
}
