// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HEAVYALIEN Collector's Editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////
//                            //
//                            //
//    H E A V Y A L I E N     //
//    Collector's Edition     //
//                            //
//                            //
//    Thank you!              //
//                            //
//                            //
////////////////////////////////


contract ALIEN is ERC1155Creator {
    constructor() ERC1155Creator("HEAVYALIEN Collector's Editions", "ALIEN") {}
}
