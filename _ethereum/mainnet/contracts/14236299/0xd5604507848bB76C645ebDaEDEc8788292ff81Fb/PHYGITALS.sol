
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Phygital NFT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                           //
//                                                                                                                           //
//    This is my signature. Includes all here minted phygital assets. You get the physical asset you are buying as NFT !!    //
//                                                                                                                           //
//                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PHYGITALS is ERC721Creator {
    constructor() ERC721Creator("Phygital NFT", "PHYGITALS") {}
}
