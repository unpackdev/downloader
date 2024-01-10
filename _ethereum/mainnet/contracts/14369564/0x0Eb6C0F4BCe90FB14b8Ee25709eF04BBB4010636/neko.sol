
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: neko test
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    　 ∧∧         //
//    　(,,ﾟДﾟ)　    //
//                 //
//                 //
/////////////////////


contract neko is ERC721Creator {
    constructor() ERC721Creator("neko test", "neko") {}
}
