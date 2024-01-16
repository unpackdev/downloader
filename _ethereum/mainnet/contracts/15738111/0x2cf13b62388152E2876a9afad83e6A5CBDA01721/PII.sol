
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Princess Island
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    PII    //
//           //
//           //
///////////////


contract PII is ERC721Creator {
    constructor() ERC721Creator("Princess Island", "PII") {}
}
