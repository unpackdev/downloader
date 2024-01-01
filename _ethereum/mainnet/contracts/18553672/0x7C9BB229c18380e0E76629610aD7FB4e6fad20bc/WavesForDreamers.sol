// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Waves For Dreamers
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//    (: Should've minted an Uncontainable Dreams :)    //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract WavesForDreamers is ERC1155Creator {
    constructor() ERC1155Creator("Waves For Dreamers", "WavesForDreamers") {}
}
