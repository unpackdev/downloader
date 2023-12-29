// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Peekcell Minis
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//                                                          //
//      ___         _          _ _   __  __ _      _        //
//     | _ \___ ___| |____ ___| | | |  \/  (_)_ _ (_)___    //
//     |  _/ -_) -_) / / _/ -_) | | | |\/| | | ' \| (_-<    //
//     |_| \___\___|_\_\__\___|_|_| |_|  |_|_|_||_|_/__/    //
//                                                          //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract PEEKM is ERC721Creator {
    constructor() ERC721Creator("Peekcell Minis", "PEEKM") {}
}
