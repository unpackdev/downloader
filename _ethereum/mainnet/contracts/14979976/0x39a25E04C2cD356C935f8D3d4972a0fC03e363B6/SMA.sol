
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Stashbox Photography
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//                                                  //
//     ___ ____  __   ___ _   _ ____ _____ _  _     //
//    / __(_  _)/__\ / __( )_( (  _ (  _  ( \/ )    //
//    \__ \ )( /(__)\\__ \) _ ( ) _ <)(_)( )  (     //
//    (___/(__(__)(__(___(_) (_(____(_____(_/\_)    //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract SMA is ERC721Creator {
    constructor() ERC721Creator("Stashbox Photography", "SMA") {}
}
