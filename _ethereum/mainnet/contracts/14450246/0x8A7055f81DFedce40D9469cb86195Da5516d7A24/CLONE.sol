
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CloneX Originals
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////
//                                                                                   //
//                                                                                   //
//    🧬 CLONE X 🧬 **Certified by [Opensea](https://opensea.io)**                   //
//    20,000 next-gen Avatars, by RTFKT and Takashi Murakami 🌸                      //
//    If you own a clone with even one Murakami trait please read the                //
//    terms regarding third-party content here: https://rtfkt.com/legal-2B.          //
//    You are not entitled to a commercial license if you own an avatar with any     //
//    traits created by Murakami.                                                    //
//                                                                                   //
//                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////


contract CLONE is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
