
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: mtnman's pfp
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//    xxxxxxxxxxxxx xxxxxxxxxxxxx    //
//    xxxxxxxxxxxx   xxxxxxxxxxxx    //
//    xxxxxxxxxxx     xxxxxxxxxxx    //
//    xxxxxxxxx         xxxxxxxxx    //
//    xxxxxxx             xxxxxxx    //
//    xxxx                   xxxx    //
//                                   //
//                                   //
///////////////////////////////////////


contract mpfp is ERC721Creator {
    constructor() ERC721Creator("mtnman's pfp", "mpfp") {}
}
