
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Journeys Through London
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////
//                                                                //
//                                                                //
//      ______                   _       ____          __         //
//     /_  __/___  ____ ___     | |     / / /_  __  __/ /____     //
//      / / / __ \/ __ `__ \    | | /| / / __ \/ / / / __/ _ \    //
//     / / / /_/ / / / / / /    | |/ |/ / / / / /_/ / /_/  __/    //
//    /_/  \____/_/ /_/ /_/     |__/|__/_/ /_/\__, /\__/\___/     //
//                                           /____/               //
//                                                                //
//                                                                //
//                                                                //
////////////////////////////////////////////////////////////////////


contract JTL is ERC721Creator {
    constructor() ERC721Creator("Journeys Through London", "JTL") {}
}
