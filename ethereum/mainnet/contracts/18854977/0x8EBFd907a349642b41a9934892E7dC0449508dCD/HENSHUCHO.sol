// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Chief Editor
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////
//                                                               //
//                                                               //
//     _____ _____ _____ _____ _____ _____ _____ _____ _____     //
//    |  |  |   __|   | |   __|  |  |  |  |     |  |  |     |    //
//    |     |   __| | | |__   |     |  |  |   --|     |  |  |    //
//    |__|__|_____|_|___|_____|__|__|_____|_____|__|__|_____|    //
//                                                               //
//                                                               //
///////////////////////////////////////////////////////////////////


contract HENSHUCHO is ERC1155Creator {
    constructor() ERC1155Creator("Chief Editor", "HENSHUCHO") {}
}
