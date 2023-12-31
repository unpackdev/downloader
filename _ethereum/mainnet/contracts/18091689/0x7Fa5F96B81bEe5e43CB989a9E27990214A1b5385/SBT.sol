// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sky Blue Tee
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    𝙿𝚑𝚘𝚝𝚘𝚐𝚛𝚊𝚙𝚑𝚢 𝙱𝚢 𝚂/𝚃    //
//                                         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract SBT is ERC721Creator {
    constructor() ERC721Creator("Sky Blue Tee", "SBT") {}
}
