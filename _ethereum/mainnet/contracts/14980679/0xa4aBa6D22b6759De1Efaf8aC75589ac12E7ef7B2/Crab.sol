
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Crabby
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    (*)    //
//           //
//           //
///////////////


contract Crab is ERC721Creator {
    constructor() ERC721Creator("Crabby", "Crab") {}
}
