
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: vincent
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//                                                 //
//     _  _  ____  _  _  ___  ____  _  _  ____     //
//    ( \/ )(_  _)( \( )/ __)( ___)( \( )(_  _)    //
//     \  /  _)(_  )  (( (__  )__)  )  (   )(      //
//      \/  (____)(_)\_)\___)(____)(_)\_) (__)     //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract vct is ERC721Creator {
    constructor() ERC721Creator("vincent", "vct") {}
}
