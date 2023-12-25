// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: You Want Some - Chari Ticket
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////
//             //
//             //
//    Chari    //
//             //
//             //
/////////////////


contract ChariTicket is ERC1155Creator {
    constructor() ERC1155Creator("You Want Some - Chari Ticket", "ChariTicket") {}
}
