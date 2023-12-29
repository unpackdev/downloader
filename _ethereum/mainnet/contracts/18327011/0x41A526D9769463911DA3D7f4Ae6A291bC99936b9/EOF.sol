// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: End of Food
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//     #####   ###   #####    //
//     ##     ## ##  ##       //
//     ##     ## ##  ##       //
//     ####   ## ##  ####     //
//     ##     ## ##  ##       //
//     ##     ## ##  ##       //
//     #####   ###   ##       //
//                            //
//                            //
////////////////////////////////


contract EOF is ERC721Creator {
    constructor() ERC721Creator("End of Food", "EOF") {}
}
