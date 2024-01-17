
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: metafive
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//                           //
//            |.-----.|      //
//            ||x . x||      //
//            ||_.-._||      //
//            `--)-(--`      //
//           __[=== o]___    //
//          |:::::::::::|    //
//          `-=========-`    //
//                           //
//                           //
///////////////////////////////


contract meta5 is ERC721Creator {
    constructor() ERC721Creator("metafive", "meta5") {}
}
