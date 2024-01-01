// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: the creeper
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    crp    //
//           //
//           //
///////////////


contract CRP is ERC721Creator {
    constructor() ERC721Creator("the creeper", "CRP") {}
}
