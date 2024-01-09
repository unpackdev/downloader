
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: peenpoon
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                                                   //
//         ___ ___ ___ _  _ ___  ___   ___  _  _     //
//      ||| _ \ __| __| \| | _ \/ _ \ / _ \| \| |    //
//     (_-<  _/ _|| _|| .` |  _/ (_) | (_) | .` |    //
//     / _/_| |___|___|_|\_|_|  \___/ \___/|_|\_|    //
//      ||                                           //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract peenpoon is ERC721Creator {
    constructor() ERC721Creator("peenpoon", "peenpoon") {}
}
