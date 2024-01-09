
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: happy dog
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//    zuo da sheng lv de shi qing ;bu duan fu li ;happy    //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract happydog is ERC721Creator {
    constructor() ERC721Creator("happy dog", "happydog") {}
}
