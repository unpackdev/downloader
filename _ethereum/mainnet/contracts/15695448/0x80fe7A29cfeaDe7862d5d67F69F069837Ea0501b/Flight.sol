
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Flight
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//     ___         __       ___     //
//    |__  |    | / _` |__|  |      //
//    |    |___ | \__> |  |  |      //
//                                  //
//                                  //
//////////////////////////////////////


contract Flight is ERC721Creator {
    constructor() ERC721Creator("Flight", "Flight") {}
}
