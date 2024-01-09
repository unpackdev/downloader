
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ghostskater
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                //
//                                                                                                                //
//                                                                                                                //
//      ________.__                    __          __            __                                               //
//     /  _____/|  |__   ____  _______/  |_  _____|  | _______ _/  |_  ____                                       //
//    /   \  ___|  |  \ /  _ \/  ___/\   __\/  ___/  |/ /\__  \\   __\/ __ \                                      //
//    \    \_\  \   Y  (  <_> )___ \  |  |  \___ \|    <  / __ \|  | \  ___/                                      //
//     \______  /___|  /\____/____  > |__| /____  >__|_ \(____  /__|  \___  >                                     //
//            \/     \/           \/            \/     \/     \/          \/                                      //
//                                                                                                                //
//    Bomberhead  is the original  GhostSkater: The Bomberhead is the first NFT for skateboarding enthusiasts.    //
//    Bomberhead NFTs provide access to gatherings, exhibits, and cool stuff in the Metaverse and real life.      //
//                                                                                                                //
//                                                                                                                //
//                                                                                                                //
//                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BomberheadNFT is ERC721Creator {
    constructor() ERC721Creator("Ghostskater", "BomberheadNFT") {}
}
