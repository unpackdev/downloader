
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: minicat
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////
//               //
//               //
//    minicat    //
//               //
//               //
///////////////////


contract minicat is ERC721Creator {
    constructor() ERC721Creator("minicat", "minicat") {}
}
