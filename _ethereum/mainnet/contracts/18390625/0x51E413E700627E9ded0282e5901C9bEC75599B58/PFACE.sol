// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Catalogue by PFACE
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//                                           //
//       ))    wWw           c  c  wWw       //
//      (o0)-. (O)_   /)     (OO)  (O)_      //
//       | (_))/ __)(o)(O) ,'.--.) / __)     //
//       | .-'/ (    //\\ / //_|_\/ (        //
//       |(  (  _)  |(__)|| \___ (  _)       //
//        \) / /    /,-. |'.    ) \ \_       //
//        (  )/    -'   ''  `-.'   \__)      //
//                                           //
//                                           //
//                                           //
///////////////////////////////////////////////


contract PFACE is ERC1155Creator {
    constructor() ERC1155Creator("The Catalogue by PFACE", "PFACE") {}
}
