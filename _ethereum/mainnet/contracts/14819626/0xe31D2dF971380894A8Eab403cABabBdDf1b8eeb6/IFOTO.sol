
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: IkkoFoto
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//      ___ _    _         _____     _            //
//     |_ _| | _| | _____ |  ___|__ | |_ ___      //
//      | || |/ / |/ / _ \| |_ / _ \| __/ _ \     //
//      | ||   <|   < (_) |  _| (_) | || (_) |    //
//     |___|_|\_\_|\_\___/|_|  \___/ \__\___/     //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract IFOTO is ERC721Creator {
    constructor() ERC721Creator("IkkoFoto", "IFOTO") {}
}
