// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: METABUS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    MBP    //
//           //
//           //
///////////////


contract MBP is ERC721Creator {
    constructor() ERC721Creator("METABUS", "MBP") {}
}
