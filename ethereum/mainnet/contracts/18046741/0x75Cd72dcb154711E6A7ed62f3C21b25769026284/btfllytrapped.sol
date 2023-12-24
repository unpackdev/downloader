// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Beautifully Trapped
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                         //
//                                                                                         //
//    trapped, just trying to make it as an artist! Shout to Mac and artists out there!    //
//                                                                                         //
//                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////


contract btfllytrapped is ERC721Creator {
    constructor() ERC721Creator("Beautifully Trapped", "btfllytrapped") {}
}
