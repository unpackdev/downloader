
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mya Parker 1of1s
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    Mya    //
//           //
//           //
///////////////


contract MYA is ERC721Creator {
    constructor() ERC721Creator("Mya Parker 1of1s", "MYA") {}
}
