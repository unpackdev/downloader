// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Unidentified art object
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//     _  _ _  _ ___  _ _  _ ____ ___ ___ ____     //
//     |  | |\ | |  \ | |\ | |___  |   |  |__|     //
//     |__| | \| |__/ | | \| |___  |   |  |  |     //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract UAO is ERC721Creator {
    constructor() ERC721Creator("Unidentified art object", "UAO") {}
}
