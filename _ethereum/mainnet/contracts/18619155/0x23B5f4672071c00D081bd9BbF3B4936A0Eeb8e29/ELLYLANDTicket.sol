// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: You Want Some - ELLYLAND Ticket
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////
//                //
//                //
//    ELLYLAND    //
//                //
//                //
////////////////////


contract ELLYLANDTicket is ERC1155Creator {
    constructor() ERC1155Creator("You Want Some - ELLYLAND Ticket", "ELLYLANDTicket") {}
}
