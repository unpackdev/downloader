// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Loyalty Badges
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//     +-+-+-+-+ +-+-+-+-+-+-+-+    //
//     |P|I|X|L| |P|A|L|A|Z|Z|O|    //
//     +-+-+-+-+ +-+-+-+-+-+-+-+    //
//                                  //
//                                  //
//////////////////////////////////////


contract ARF is ERC1155Creator {
    constructor() ERC1155Creator("Loyalty Badges", "ARF") {}
}
