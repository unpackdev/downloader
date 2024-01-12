
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 𝐄𝐗𝐈𝐒𝐓𝐄𝐍𝐓𝐈𝐀𝐋 𝐉𝐎𝐔𝐑𝐍𝐄𝐘
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    Art is a journey.    //
//                         //
//                         //
/////////////////////////////


contract EJ is ERC721Creator {
    constructor() ERC721Creator(unicode"𝐄𝐗𝐈𝐒𝐓𝐄𝐍𝐓𝐈𝐀𝐋 𝐉𝐎𝐔𝐑𝐍𝐄𝐘", "EJ") {}
}
