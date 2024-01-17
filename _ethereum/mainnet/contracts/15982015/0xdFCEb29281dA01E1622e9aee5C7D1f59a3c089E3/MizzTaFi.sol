
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MizzTaFi
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//                                            //
//      __  __ _      _______    ______ _     //
//     |  \/  (_)    |__   __|  |  ____(_)    //
//     | \  / |_ _______| | __ _| |__   _     //
//     | |\/| | |_  /_  / |/ _` |  __| | |    //
//     | |  | | |/ / / /| | (_| | |    | |    //
//     |_|  |_|_/___/___|_|\__,_|_|    |_|    //
//                                            //
//                                            //
//                                            //
//                                            //
//                                            //
////////////////////////////////////////////////


contract MizzTaFi is ERC721Creator {
    constructor() ERC721Creator("MizzTaFi", "MizzTaFi") {}
}
