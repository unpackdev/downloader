
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Junko!
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//                                               //
//      _________.__    .__       .__    .__     //
//     /   _____/|  |__ |__| _____|  |__ |__|    //
//     \_____  \ |  |  \|  |/  ___/  |  \|  |    //
//     /        \|   Y  \  |\___ \|   Y  \  |    //
//    /_______  /|___|  /__/____  >___|  /__|    //
//            \/      \/        \/     \/        //
//                                               //
//                                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract junko is ERC721Creator {
    constructor() ERC721Creator("Junko!", "junko") {}
}
