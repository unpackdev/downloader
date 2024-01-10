
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mystic Goddesses by AMYLILI
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//                                                      //
//           +-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+-+          //
//           |M|Y|S|T|I|C| |G|O|D|D|E|S|S|E|S|          //
//           +-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+-+          //
//                 +-+-+ +-+-+-+-+-+-+-+                //
//                 |B|Y| |A|M|Y|L|I|L|I|                //
//                 +-+-+ +-+-+-+-+-+-+-+                //
//                                                      //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract MGA is ERC721Creator {
    constructor() ERC721Creator("Mystic Goddesses by AMYLILI", "MGA") {}
}
