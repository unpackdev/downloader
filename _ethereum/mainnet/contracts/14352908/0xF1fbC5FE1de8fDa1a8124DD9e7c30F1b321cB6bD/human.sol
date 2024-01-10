
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: to the earth
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//    to the moon？to the sun？no！we are human.we live on the earth!    //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract human is ERC721Creator {
    constructor() ERC721Creator("to the earth", "human") {}
}
