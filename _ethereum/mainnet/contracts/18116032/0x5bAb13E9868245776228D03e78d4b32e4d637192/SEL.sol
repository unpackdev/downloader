// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sel·lecte
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//       _____      _   _           _           //
//      / ____|    | | | |         | |          //
//     | (___   ___| |_| | ___  ___| |_ ___     //
//      \___ \ / _ \ (_) |/ _ \/ __| __/ _ \    //
//      ____) |  __/ | | |  __/ (__| ||  __/    //
//     |_____/ \___|_| |_|\___|\___|\__\___|    //
//                                              //
//                                              //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract SEL is ERC721Creator {
    constructor() ERC721Creator(unicode"Sel·lecte", "SEL") {}
}
