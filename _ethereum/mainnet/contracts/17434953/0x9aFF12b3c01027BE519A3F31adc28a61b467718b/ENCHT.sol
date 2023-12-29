// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Enchanted Tides
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//    •°¤*´¯`*¤°• Enchanted Tides •°¤*´¯`*¤°••    //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract ENCHT is ERC721Creator {
    constructor() ERC721Creator("Enchanted Tides", "ENCHT") {}
}
