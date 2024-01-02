// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Feast
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                   //
//                                                                                                                                                   //
//    Humanity and ethics have always been my concern. I want to talk about them in my own way.                                                      //
//    A famous politician is feasting, drinking the blood of youth to sustain his rule. He is left handed and always engages people in his feast.    //
//    No one can resist him.                                                                                                                         //
//                                                                                                                                                   //
//                                                                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FS is ERC721Creator {
    constructor() ERC721Creator("Feast", "FS") {}
}
