
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: metaregular
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//                _                          _              //
//      _ __  ___| |_ __ _ _ _ ___ __ _ _  _| |__ _ _ _     //
//     | '  \/ -_)  _/ _` | '_/ -_) _` | || | / _` | '_|    //
//     |_|_|_\___|\__\__,_|_| \___\__, |\_,_|_\__,_|_|      //
//                                |___/                     //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract meta is ERC721Creator {
    constructor() ERC721Creator("metaregular", "meta") {}
}
