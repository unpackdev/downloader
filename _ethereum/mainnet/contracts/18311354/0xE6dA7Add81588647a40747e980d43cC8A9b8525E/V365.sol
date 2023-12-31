// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VIRTUOSO 365 Editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//                                          //
//    ██    ██ ██████   ██████  ███████     //
//    ██    ██      ██ ██       ██          //
//    ██    ██  █████  ███████  ███████     //
//     ██  ██       ██ ██    ██      ██     //
//      ████   ██████   ██████  ███████     //
//                                          //
//                                          //
//                                          //
//                                          //
//                                          //
//////////////////////////////////////////////


contract V365 is ERC1155Creator {
    constructor() ERC1155Creator("VIRTUOSO 365 Editions", "V365") {}
}
