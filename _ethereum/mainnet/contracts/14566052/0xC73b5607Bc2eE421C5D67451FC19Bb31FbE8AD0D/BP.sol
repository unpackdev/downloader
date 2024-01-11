
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bigger Problems by Grace Hoyle
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//                                                                    //
//      ___ _                     ___         _    _                  //
//     | _ |_)__ _ __ _ ___ _ _  | _ \_ _ ___| |__| |___ _ __  ___    //
//     | _ \ / _` / _` / -_) '_| |  _/ '_/ _ \ '_ \ / -_) '  \(_-<    //
//     |___/_\__, \__, \___|_|   |_| |_| \___/_.__/_\___|_|_|_/__/    //
//           |___/|___/                                               //
//                                                                    //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract BP is ERC721Creator {
    constructor() ERC721Creator("Bigger Problems by Grace Hoyle", "BP") {}
}
