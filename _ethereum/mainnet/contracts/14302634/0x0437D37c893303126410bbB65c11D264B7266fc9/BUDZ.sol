
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 420 Budz The Founders Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//     _  _ ___   ___    ____            _         //
//    | || |__ \ / _ \  |  _ \          | |        //
//    | || |_ ) | | | | | |_) |_   _  __| |____    //
//    |__   _/ /| | | | |  _ <| | | |/ _` |_  /    //
//       | |/ /_| |_| | | |_) | |_| | (_| |/ /     //
//       |_|____|\___/  |____/ \__,_|\__,_/___|    //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract BUDZ is ERC721Creator {
    constructor() ERC721Creator("420 Budz The Founders Collection", "BUDZ") {}
}
