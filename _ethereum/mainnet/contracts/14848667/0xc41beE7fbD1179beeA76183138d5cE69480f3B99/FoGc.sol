
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Festival of Gratitude _ Cakes
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//                 _                    _     _     //
//                | |                  | |   | |    //
//       __ _ _ __| |___      __   _ __| | __| |    //
//      / _` | '__| __\ \ /\ / /  | '__| |/ _` |    //
//     | (_| | |  | |_ \ V  V /   | |  | | (_| |    //
//      \__,_|_|   \__| \_/\_/    |_|  |_|\__,_|    //
//                                                  //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract FoGc is ERC721Creator {
    constructor() ERC721Creator("Festival of Gratitude _ Cakes", "FoGc") {}
}
