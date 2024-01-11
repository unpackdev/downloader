
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: some NFTS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    Let's go!    //
//                 //
//                 //
/////////////////////


contract mrktx is ERC721Creator {
    constructor() ERC721Creator("some NFTS", "mrktx") {}
}
