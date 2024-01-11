
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LATASHA
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//                                                     //
//     _        _  _____  _    ____  _   _    _        //
//    | |      / \|_   _|/ \  / ___|| | | |  / \       //
//    | |     / _ \ | | / _ \ \___ \| |_| | / _ \      //
//    | |___ / ___ \| |/ ___ \ ___) |  _  |/ ___ \     //
//    |_____/_/   \_|_/_/   \_|____/|_| |_/_/   \_\    //
//                                                     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract LATASHA is ERC721Creator {
    constructor() ERC721Creator("LATASHA", "LATASHA") {}
}
