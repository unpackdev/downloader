
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: flowermei
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//                                //
//                                //
//      .-.                       //
//     /    \                     //
//     | .`. ;  ___ .-. .-.       //
//     | |(___)(   )   '   \      //
//     | |_     |  .-.  .-. ;     //
//    (   __)   | |  | |  | |     //
//     | |      | |  | |  | |     //
//     | |      | |  | |  | |     //
//     | |      | |  | |  | |     //
//     | |      | |  | |  | |     //
//    (___)    (___)(___)(___)    //
//                                //
//                                //
//                                //
//                                //
//                                //
//                                //
////////////////////////////////////


contract fm is ERC721Creator {
    constructor() ERC721Creator("flowermei", "fm") {}
}
