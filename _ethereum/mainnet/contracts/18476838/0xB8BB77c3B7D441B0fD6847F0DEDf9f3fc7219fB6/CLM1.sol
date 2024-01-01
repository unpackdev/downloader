// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CLM1
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////
//               //
//               //
//    CLM1xyz    //
//               //
//               //
///////////////////


contract CLM1 is ERC721Creator {
    constructor() ERC721Creator("CLM1", "CLM1") {}
}
