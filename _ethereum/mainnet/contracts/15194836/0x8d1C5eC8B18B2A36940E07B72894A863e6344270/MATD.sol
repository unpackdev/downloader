
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Matthias Doppler
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//                  _   _   _    _              //
//                 ( ) ( ) ( )  (_)             //
//     __  __  ___ | | | | | |_  _  ___  __     //
//    ( _`'_ )( o )( _)( _)( _ )( )( o )(_'     //
//    /_\`'/_\/_^_\/_\ /_\ /_\||/_\/_^_\/__)    //
//                                              //
//       _                 _                    //
//      ( )               ( )                   //
//     _| | ___  ___  ___ | | ___  __           //
//    / o )( o )( o \( o \( )( o_)( _)          //
//    \___\ \_/ / __// __//_\ \(  /_\           //
//              |_|  |_|                        //
//                                              //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract MATD is ERC721Creator {
    constructor() ERC721Creator("Matthias Doppler", "MATD") {}
}
