// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JEFSTYLE EDITION
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////
//                           //
//                           //
//       ___ ___________     //
//      |_  |  ___|  ___|    //
//        | | |__ | |_       //
//        | |  __||  _|      //
//    /\__/ / |___| |        //
//    \____/\____/\_         //
//                           //
//                           //
///////////////////////////////


contract JFED is ERC1155Creator {
    constructor() ERC1155Creator("JEFSTYLE EDITION", "JFED") {}
}
