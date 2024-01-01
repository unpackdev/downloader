// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CARNAVAIS ARTIFICIAIS
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//    Carnavais que nunca foram, mas que podiam ter sido.    //
//    por Pedro Garcia.                                      //
//                                                           //
//    www.pedrogarcia.com.br                                 //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract CARNA is ERC1155Creator {
    constructor() ERC1155Creator("CARNAVAIS ARTIFICIAIS", "CARNA") {}
}
