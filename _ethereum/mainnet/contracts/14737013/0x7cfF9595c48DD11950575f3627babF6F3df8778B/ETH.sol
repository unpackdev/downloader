
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: eidollucinations
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//                                               //
//         __  _____.__                          //
//        |__|/ ____\__|______   ___________     //
//        |  \   __\|  \_  __ \_/ __ \_  __ \    //
//        |  ||  |  |  ||  | \/\  ___/|  | \/    //
//    /\__|  ||__|  |__||__|    \___  >__|       //
//    \______|                      \/           //
//                                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract ETH is ERC721Creator {
    constructor() ERC721Creator("eidollucinations", "ETH") {}
}
