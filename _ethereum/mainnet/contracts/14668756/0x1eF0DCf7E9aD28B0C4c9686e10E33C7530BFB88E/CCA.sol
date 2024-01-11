
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: City Collection Alpha
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                             //
//                                                                                                                             //
//                      _       _       _          _____ _ _            _____      _ _           _   _               _____     //
//                     | |     (_)     (_)        / ____(_) |          / ____|    | | |         | | (_)             |_   _|    //
//       __ _ _ __   __| | __ _ _ _ __  _  __ _  | |     _| |_ _   _  | |     ___ | | | ___  ___| |_ _  ___  _ __     | |      //
//      / _` | '_ \ / _` |/ _` | | '_ \| |/ _` | | |    | | __| | | | | |    / _ \| | |/ _ \/ __| __| |/ _ \| '_ \    | |      //
//     | (_| | | | | (_| | (_| | | | | | | (_| | | |____| | |_| |_| | | |___| (_) | | |  __/ (__| |_| | (_) | | | |  _| |_     //
//      \__,_|_| |_|\__,_|\__, |_|_| |_| |\__,_|  \_____|_|\__|\__, |  \_____\___/|_|_|\___|\___|\__|_|\___/|_| |_| |_____|    //
//                         __/ |      _/ |                      __/ |                                                          //
//                                                                                                                             //
//    ag City Collection I is the genesis custom contract photography collection by André Ginja.                               //
//    This collection represents his views of his hometown Lisbon, Portugal.                                                   //
//    All pieces are color-edited to match the artist's personality, providing unique pieces of such a special city.           //
//                                                                                                                             //
//    andginja 2022                                                                                                            //
//                                                                                                                             //
//                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CCA is ERC721Creator {
    constructor() ERC721Creator("City Collection Alpha", "CCA") {}
}
