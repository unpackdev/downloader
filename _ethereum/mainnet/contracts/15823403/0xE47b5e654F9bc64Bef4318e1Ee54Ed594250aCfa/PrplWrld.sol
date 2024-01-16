
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Purple World by LizGear
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//                                                           //
//    ,------.                                               //
//    |  .--. ',--.,--.,--.--.     ,---. ,--.,--.,--.--.     //
//    |  '--' ||  ||  ||  .--'    | .-. ||  ||  ||  .--'     //
//    |  | --' '  ''  '|  |       | '-' ''  ''  '|  |        //
//    `--'      `----' `--'       |  |-'  `----' `--'        //
//                                `--'                       //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract PrplWrld is ERC721Creator {
    constructor() ERC721Creator("Purple World by LizGear", "PrplWrld") {}
}
