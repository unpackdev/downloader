
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Grizzys
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                        //
//                                                                                                        //
//    Building a world of wholesome and fun characters to represent the human spirit in the metaverse!    //
//                                                                                                        //
//                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GRIZZY is ERC721Creator {
    constructor() ERC721Creator("Grizzys", "GRIZZY") {}
}
