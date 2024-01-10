
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SHINE!
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//    8   8  8 8""""8 8"""8  8""""8 8"""88 8""""8 8""""8    //
//    8   8  8 8    8 8   8  8    8 8    8 8    " 8         //
//    8e  8  8 8eeee8 8eee8e 8e   8 8    8 8e     8eeeee    //
//    88  8  8 88   8 88   8 88   8 8    8 88  ee     88    //
//    88  8  8 88   8 88   8 88   8 8    8 88   8 e   88    //
//    88ee8ee8 88   8 88   8 88eee8 8eeee8 88eee8 8eee88    //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract WDS is ERC721Creator {
    constructor() ERC721Creator("SHINE!", "WDS") {}
}
