// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Friends With Benefits
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//                                              //
//       ▄████████  ▄█     █▄  ▀█████████▄      //
//      ███    ███ ███     ███   ███    ███     //
//      ███    █▀  ███     ███   ███    ███     //
//     ▄███▄▄▄     ███     ███  ▄███▄▄▄██▀      //
//    ▀▀███▀▀▀     ███     ███ ▀▀███▀▀▀██▄      //
//      ███        ███     ███   ███    ██▄     //
//      ███        ███ ▄█▄ ███   ███    ███     //
//      ███         ▀███▀███▀  ▄█████████▀      //
//                                              //
//                                              //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract FWB is ERC1155Creator {
    constructor() ERC1155Creator("Friends With Benefits", "FWB") {}
}
