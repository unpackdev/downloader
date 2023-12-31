// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SneakerHeads Collectibles
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//      __  __  _ ___  __  _  _____ ___ _  _ ___  __  __    __      //
//    /' _/|  \| | __|/  \| |/ / __| _ \ || | __|/  \| _\ /' _/     //
//    `._`.| | ' | _|| /\ |   <| _|| v / >< | _|| /\ | v |`._`.     //
//    |___/|_|\__|___|_||_|_|\_\___|_|_\_||_|___|_||_|__/ |___/     //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract SHCOL is ERC721Creator {
    constructor() ERC721Creator("SneakerHeads Collectibles", "SHCOL") {}
}
