// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: North-South-North
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    ▄▀▀▄ ▄▀▄  ▄▀▀▀▀▄          //
//    █  █ ▀  █ █    █          //
//    ▐  █    █ ▐    █          //
//      █    █      █           //
//    ▄▀   ▄▀     ▄▀▄▄▄▄▄▄▀     //
//    █    █      █             //
//    ▐    ▐      ▐             //
//                              //
//                              //
//////////////////////////////////


contract NSN is ERC721Creator {
    constructor() ERC721Creator("North-South-North", "NSN") {}
}
