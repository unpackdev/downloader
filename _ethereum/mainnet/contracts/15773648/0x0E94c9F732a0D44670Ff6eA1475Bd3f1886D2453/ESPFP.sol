
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Engulf Society PFPs
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//                   @                   //
//                @@@@@@@                //
//    @@     @@@@@@@@@@@@@@@@@     @@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@                   @@@@@@    //
//    @@                           @@    //
//      @                         @      //
//           engulfsociety.eth           //
//                                       //
//                                       //
///////////////////////////////////////////


contract ESPFP is ERC721Creator {
    constructor() ERC721Creator("Engulf Society PFPs", "ESPFP") {}
}
