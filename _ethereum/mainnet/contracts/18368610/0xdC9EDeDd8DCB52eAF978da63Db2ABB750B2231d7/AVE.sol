// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AVE
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    AVE    //
//           //
//           //
///////////////


contract AVE is ERC721Creator {
    constructor() ERC721Creator("AVE", "AVE") {}
}
