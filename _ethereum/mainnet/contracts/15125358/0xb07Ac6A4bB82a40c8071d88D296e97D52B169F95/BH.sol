
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BoundHedgie
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//      ___                   _ _  _        _      _         //
//     | _ ) ___ _  _ _ _  __| | || |___ __| |__ _(_)___     //
//     | _ \/ _ \ || | ' \/ _` | __ / -_) _` / _` | / -_)    //
//     |___/\___/\_,_|_||_\__,_|_||_\___\__,_\__, |_\___|    //
//                                           |___/           //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract BH is ERC721Creator {
    constructor() ERC721Creator("BoundHedgie", "BH") {}
}
