// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GOOD VIP Club Membership
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    GOOD VIP Club Membership    //
//                                //
//                                //
////////////////////////////////////


contract GVCM is ERC721Creator {
    constructor() ERC721Creator("GOOD VIP Club Membership", "GVCM") {}
}
