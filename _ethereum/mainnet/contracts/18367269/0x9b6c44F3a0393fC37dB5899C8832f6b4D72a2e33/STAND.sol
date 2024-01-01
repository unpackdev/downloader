// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Stand With Israel
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    Snag stands with Israel    //
//                               //
//                               //
///////////////////////////////////


contract STAND is ERC1155Creator {
    constructor() ERC1155Creator("Stand With Israel", "STAND") {}
}
