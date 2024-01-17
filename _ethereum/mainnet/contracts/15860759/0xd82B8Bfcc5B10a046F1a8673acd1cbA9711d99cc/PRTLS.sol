
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Portals
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                     //
//                                                                                                                                     //
//    PORTALS a series of photographs by Ismail Elaaddioui, contract deployed originally 08/02/2022 now newly deployed on Manifold     //
//                                                                                                                                     //
//                                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PRTLS is ERC721Creator {
    constructor() ERC721Creator("Portals", "PRTLS") {}
}
