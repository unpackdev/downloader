// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mediterranean
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    Mediterranean    //
//                     //
//                     //
/////////////////////////


contract MRN is ERC721Creator {
    constructor() ERC721Creator("Mediterranean", "MRN") {}
}
