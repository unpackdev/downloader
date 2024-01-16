
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dopamine
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//    (((((((((((((((oooooooo))))))))))))))))    //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract dope is ERC721Creator {
    constructor() ERC721Creator("Dopamine", "dope") {}
}
