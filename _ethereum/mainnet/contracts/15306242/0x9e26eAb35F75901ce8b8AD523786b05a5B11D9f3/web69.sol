
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: web69.id
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//                  _      __   ___   _     _     //
//    __      _____| |__  / /_ / _ \ (_) __| |    //
//    \ \ /\ / / _ \ '_ \| '_ \ (_) || |/ _` |    //
//     \ V  V /  __/ |_) | (_) \__, || | (_| |    //
//      \_/\_/ \___|_.__/ \___/  /_(_)_|\__,_|    //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract web69 is ERC721Creator {
    constructor() ERC721Creator("web69.id", "web69") {}
}
