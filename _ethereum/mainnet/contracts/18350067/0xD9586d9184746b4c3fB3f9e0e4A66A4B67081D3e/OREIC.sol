// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ōREIC Memorial
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//                 //
//    ┏┓┳┓┏┓┳┏┓    //
//    ┃┃┣┫┣ ┃┃     //
//    ┗┛┛┗┗┛┻┗┛    //
//                 //
//                 //
//                 //
/////////////////////


contract OREIC is ERC721Creator {
    constructor() ERC721Creator(unicode"ōREIC Memorial", "OREIC") {}
}
