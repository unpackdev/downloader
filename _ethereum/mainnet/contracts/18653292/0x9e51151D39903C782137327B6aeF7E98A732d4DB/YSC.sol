// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ゆるすぎこれくしょん
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//    YURUSUGI    //
//                //
//                //
////////////////////


contract YSC is ERC721Creator {
    constructor() ERC721Creator(unicode"ゆるすぎこれくしょん", "YSC") {}
}
