
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: State of mind
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    MIR    //
//           //
//           //
///////////////


contract mir is ERC721Creator {
    constructor() ERC721Creator("State of mind", "mir") {}
}
