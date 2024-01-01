// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bidder Editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//                                                      //
//     __    __     ______     __         ______        //
//    /\ "-./  \   /\  __ \   /\ \       /\  __ \       //
//    \ \ \-./\ \  \ \  __ \  \ \ \____  \ \ \/\ \      //
//     \ \_\ \ \_\  \ \_\ \_\  \ \_____\  \ \_____\     //
//      \/_/  \/_/   \/_/\/_/   \/_____/   \/_____/     //
//                                                      //
//                                                      //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract BDDE is ERC1155Creator {
    constructor() ERC1155Creator("Bidder Editions", "BDDE") {}
}
