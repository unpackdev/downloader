
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BurtonCustomesque
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//    \_____  \  /  _____/ /  _____/ \_____  \      //
//     /   |   \/   \  ___/   \  ___  /   |   \     //
//    /    |    \    \_\  \    \_\  \/    |    \    //
//    \_______  /\______  /\______  /\_______  /    //
//            \/        \/        \/         \/     //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract BqrCs is ERC721Creator {
    constructor() ERC721Creator("BurtonCustomesque", "BqrCs") {}
}
