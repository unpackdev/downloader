// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: neural rain editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////
//                            //
//                            //
//          __   _            //
//        _(  )_( )_          //
//       (_ N _  R _)         //
//      / /(_) (__)           //
//     / / / / / /            //
//    / / / / / /             //
//        d    t     n        //
//     e     i      o         //
//                i      s    //
//                            //
//                            //
////////////////////////////////


contract NRE is ERC1155Creator {
    constructor() ERC1155Creator("neural rain editions", "NRE") {}
}
