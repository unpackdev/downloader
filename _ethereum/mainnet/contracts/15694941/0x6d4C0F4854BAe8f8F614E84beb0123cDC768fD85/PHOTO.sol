
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MS MINT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//    M   M  SSS      PPPP  H  H  OOO  TTTTTT  OOO      //
//    MM MM S         P   P H  H O   O   TT   O   O     //
//    M M M  SSS      PPPP  HHHH O   O   TT   O   O     //
//    M   M     S     P     H  H O   O   TT   O   O     //
//    M   M SSSS      P     H  H  OOO    TT    OOO      //
//                                                      //
//                                                      //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract PHOTO is ERC721Creator {
    constructor() ERC721Creator("MS MINT", "PHOTO") {}
}
