// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Life Is But a Dream
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//                                                                          //
//                     ___      __                   __                     //
//     )  o _(_  _      )  _    )_)     _)_    _     ) ) _ _   _   _ _      //
//    (__ (   ) )_)   _(_ (    /__) (_( (_    (_(   /_/ ) )_) (_( ) ) )     //
//             (_         _)                             (_                 //
//                                                                          //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////


contract LIBAD is ERC721Creator {
    constructor() ERC721Creator("Life Is But a Dream", "LIBAD") {}
}
