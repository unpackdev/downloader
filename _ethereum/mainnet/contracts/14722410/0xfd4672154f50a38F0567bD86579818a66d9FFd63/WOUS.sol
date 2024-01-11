
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GOFY World of Useless Stickers
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//      ___   __  ____  _  _    _  _   __   _  _  ____     //
//     / __) /  \(  __)( \/ )  / )( \ /  \ / )( \/ ___)    //
//    ( (_ \(  O )) _)  )  /   \ /\ /(  O )) \/ (\___ \    //
//     \___/ \__/(__)  (__/    (_/\_) \__/ \____/(____/    //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract WOUS is ERC721Creator {
    constructor() ERC721Creator("GOFY World of Useless Stickers", "WOUS") {}
}
