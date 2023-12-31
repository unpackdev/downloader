// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MEME IMS Onboarding
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    🦠.🦠🦠.🦠🦠🦠.🦠🦠🦠🦠🦠    //
//                                 //
//                                 //
/////////////////////////////////////


contract MIMS is ERC1155Creator {
    constructor() ERC1155Creator("MEME IMS Onboarding", "MIMS") {}
}
