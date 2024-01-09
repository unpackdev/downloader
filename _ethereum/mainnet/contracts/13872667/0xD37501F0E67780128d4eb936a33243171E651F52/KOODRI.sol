
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: koodri_NFT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//    Hi. My name is Victoria. I am an perfomance artist.           //
//    I paint pictures with a naked body in extreme environments    //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract KOODRI is ERC721Creator {
    constructor() ERC721Creator("koodri_NFT", "KOODRI") {}
}
