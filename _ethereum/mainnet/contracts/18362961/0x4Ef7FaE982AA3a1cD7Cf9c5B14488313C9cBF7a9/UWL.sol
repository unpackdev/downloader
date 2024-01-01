// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: UniWhales DAO NFT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//            .                      //
//           ":"                     //
//         ___:____     |"\/"|       //
//       ,'        `.    \  /        //
//       |  O        \___/  |        //
//     ~^~^~^~^~UWL^~^~^~^~^~^~^~    //
//                                   //
//                                   //
///////////////////////////////////////


contract UWL is ERC721Creator {
    constructor() ERC721Creator("UniWhales DAO NFT", "UWL") {}
}
