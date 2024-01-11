
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: espen kluge
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//                                     //
//       ___  ___ _ __   ___ _ __      //
//      / _ \/ __| '_ \ / _ \ '_ \     //
//     |  __/\__ \ |_) |  __/ | | |    //
//      \___||___/ .__/ \___|_| |_|    //
//               |_|                   //
//                                     //
//                                     //
/////////////////////////////////////////


contract espen is ERC721Creator {
    constructor() ERC721Creator("espen kluge", "espen") {}
}
