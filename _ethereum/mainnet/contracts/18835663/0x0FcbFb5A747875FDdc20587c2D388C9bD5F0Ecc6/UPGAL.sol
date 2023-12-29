// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Upgrade Key
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//    |__) |__) /  \  |   /\  |   |_   |  |__|     //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract UPGAL is ERC721Creator {
    constructor() ERC721Creator("Upgrade Key", "UPGAL") {}
}
