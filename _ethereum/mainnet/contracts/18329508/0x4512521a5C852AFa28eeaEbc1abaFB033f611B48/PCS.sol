// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pieces
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//           .__                                //
//    ______ |__| ____   ____  ____   ______    //
//    \____ \|  |/ __ \_/ ___\/ __ \ /  ___/    //
//    |  |_> >  \  ___/\  \__\  ___/ \___ \     //
//    |   __/|__|\___  >\___  >___  >____  >    //
//    |__|           \/     \/    \/     \/     //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract PCS is ERC721Creator {
    constructor() ERC721Creator("Pieces", "PCS") {}
}
