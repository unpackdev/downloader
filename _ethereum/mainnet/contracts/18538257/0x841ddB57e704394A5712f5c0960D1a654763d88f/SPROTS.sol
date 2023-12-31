// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BITCOINCASH SPROTS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//     $$$$$$\  $$$$$$$\  $$$$$$$\   $$$$$$\  $$$$$$$$\  $$$$$$\      //
//    $$  __$$\ $$  __$$\ $$  __$$\ $$  __$$\ \__$$  __|$$  __$$\     //
//    $$ /  \__|$$ |  $$ |$$ |  $$ |$$ /  $$ |   $$ |   $$ /  \__|    //
//    \$$$$$$\  $$$$$$$  |$$$$$$$  |$$ |  $$ |   $$ |   \$$$$$$\      //
//     \____$$\ $$  ____/ $$  __$$< $$ |  $$ |   $$ |    \____$$\     //
//    $$\   $$ |$$ |      $$ |  $$ |$$ |  $$ |   $$ |   $$\   $$ |    //
//    \$$$$$$  |$$ |      $$ |  $$ | $$$$$$  |   $$ |   \$$$$$$  |    //
//     \______/ \__|      \__|  \__| \______/    \__|    \______/     //
//                                                                    //
//                                                                    //
//                                                                    //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract SPROTS is ERC721Creator {
    constructor() ERC721Creator("BITCOINCASH SPROTS", "SPROTS") {}
}
