
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DoughBois
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    DOH    //
//           //
//           //
///////////////


contract DOH is ERC721Creator {
    constructor() ERC721Creator("DoughBois", "DOH") {}
}
