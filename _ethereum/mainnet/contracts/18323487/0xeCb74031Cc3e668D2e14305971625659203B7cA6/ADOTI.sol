// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A Day On The Island
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////
//                                                                                //
//                                                                                //
//                                                                                //
//      __    __             ___        ____ _         _     _              _     //
//     /_`)   ))\ ___ __ _   )) ) _ _    ))  ))_  __   )) __ )) ___  _ _  __))    //
//    (( (   ((_/((_( \(/'  ((_( ((\(   ((  ((`( (('  (( _))(( ((_( ((\( ((_(     //
//                     ))                                                         //
//                                                                                //
//                                                                                //
//                                                                                //
////////////////////////////////////////////////////////////////////////////////////


contract ADOTI is ERC721Creator {
    constructor() ERC721Creator("A Day On The Island", "ADOTI") {}
}
