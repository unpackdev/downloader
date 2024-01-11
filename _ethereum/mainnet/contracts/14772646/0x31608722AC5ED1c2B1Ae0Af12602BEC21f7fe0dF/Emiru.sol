
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Emiru
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//      __|   \  | _ _|  _ \  |  |     //
//      _|   |\/ |   |     /  |  |     //
//     ___| _|  _| ___| _|_\ \__/      //
//                                     //
//                                     //
/////////////////////////////////////////


contract Emiru is ERC721Creator {
    constructor() ERC721Creator("Emiru", "Emiru") {}
}
