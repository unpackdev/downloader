// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mini Desk Potto
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    YZH    //
//           //
//           //
///////////////


contract Potto is ERC721Creator {
    constructor() ERC721Creator("Mini Desk Potto", "Potto") {}
}
