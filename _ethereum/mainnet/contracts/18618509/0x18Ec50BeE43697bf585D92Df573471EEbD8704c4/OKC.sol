// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OBELL KUR Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    OKC    //
//           //
//           //
///////////////


contract OKC is ERC721Creator {
    constructor() ERC721Creator("OBELL KUR Collection", "OKC") {}
}
