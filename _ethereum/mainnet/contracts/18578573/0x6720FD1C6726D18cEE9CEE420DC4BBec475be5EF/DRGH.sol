// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dr.Grinspoon Hommage 2.0
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                   //
//                                                                                                   //
//    This COllection is all about Hommage works, costum pieces, commissions and all other dutys.    //
//                                                                                                   //
//                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////


contract DRGH is ERC1155Creator {
    constructor() ERC1155Creator("Dr.Grinspoon Hommage 2.0", "DRGH") {}
}
