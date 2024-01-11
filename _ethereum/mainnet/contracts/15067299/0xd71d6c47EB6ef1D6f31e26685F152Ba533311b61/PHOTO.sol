
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nobody's Photography
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//     .-------------------.    //
//    /--"--.------.------/|    //
//    | AFN |__Ll__| [==] ||    //
//    |     | .--. | """" ||    //
//    |     |( () )|      ||    //
//    |     | `--' |      |/    //
//    `-----'------'------'     //
//                              //
//                              //
//////////////////////////////////


contract PHOTO is ERC721Creator {
    constructor() ERC721Creator("Nobody's Photography", "PHOTO") {}
}
