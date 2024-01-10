
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: REMINT - Prime Owner
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//        _,     ,_       //
//      .'/  ,_   \'.     //
//     |  \__( >__/  |    //
//     \    REMINT   /    //
//      '-..__ __..-'     //
//           /_\          //
//                        //
//                        //
////////////////////////////


contract REMINT is ERC721Creator {
    constructor() ERC721Creator("REMINT - Prime Owner", "REMINT") {}
}
