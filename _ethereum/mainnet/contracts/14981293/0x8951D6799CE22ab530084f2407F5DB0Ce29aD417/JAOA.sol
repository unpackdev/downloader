
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JAOAPES
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////
//                                                                                //
//                                                                                //
//    JAOApes are artistically modified APES by JustArtOut collective.            //
//    All rights and Intelectual Property reserved for the holders of JAOAPES.    //
//                                                                                //
//    JustArtOut - Collective of Artist across different fields of ARTS           //
//                                                                                //
//    Founder of JAO, JAOAPES                                                     //
//    Akashi30                                                                    //
//                                                                                //
//                                                                                //
////////////////////////////////////////////////////////////////////////////////////


contract JAOA is ERC721Creator {
    constructor() ERC721Creator("JAOAPES", "JAOA") {}
}
