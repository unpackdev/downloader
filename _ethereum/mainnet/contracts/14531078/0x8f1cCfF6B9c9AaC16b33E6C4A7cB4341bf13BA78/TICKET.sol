
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: tickets
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//     ____  __  ___  __ _  ____  ____  ____     //
//    (_  _)(  )/ __)(  / )(  __)(_  _)/ ___)    //
//      )(   )(( (__  )  (  ) _)   )(  \___ \    //
//     (__) (__)\___)(__\_)(____) (__) (____/    //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract TICKET is ERC721Creator {
    constructor() ERC721Creator("tickets", "TICKET") {}
}
