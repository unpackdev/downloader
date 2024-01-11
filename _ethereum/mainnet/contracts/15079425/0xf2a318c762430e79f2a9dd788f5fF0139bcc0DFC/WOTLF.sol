
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ward of The Lost & Forgotten
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//      ____                 _ _                //
//     |  _ \ __ _ _ __ __ _| | | __ ___  __    //
//     | |_) / _` | '__/ _` | | |/ _` \ \/ /    //
//     |  __/ (_| | | | (_| | | | (_| |>  <     //
//     |_|   \__,_|_|  \__,_|_|_|\__,_/_/\_\    //
//             twitter.com/parallax_            //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract WOTLF is ERC721Creator {
    constructor() ERC721Creator("Ward of The Lost & Forgotten", "WOTLF") {}
}
