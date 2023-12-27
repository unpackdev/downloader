// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KIDOU
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//     ____  __.___________   ________   ____ ___     //
//    |    |/ _|   \______ \  \_____  \ |    |   \    //
//    |      < |   ||    |  \  /   |   \|    |   /    //
//    |    |  \|   ||    `   \/    |    \    |  /     //
//    |____|__ \___/_______  /\_______  /______/      //
//            \/           \/         \/              //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract HOURAI is ERC721Creator {
    constructor() ERC721Creator("KIDOU", "HOURAI") {}
}
