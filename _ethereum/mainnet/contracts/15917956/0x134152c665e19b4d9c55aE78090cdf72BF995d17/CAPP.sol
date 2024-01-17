
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: car.apple
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    dog to the moon    //
//                       //
//                       //
///////////////////////////


contract CAPP is ERC721Creator {
    constructor() ERC721Creator("car.apple", "CAPP") {}
}
