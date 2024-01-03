// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MRC ARTE ONCHAIN EDITIONS
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////
//                //
//                //
//    +++         //
//    MRC         //
//    ARTE        //
//    ONCHAIN     //
//    EDITIONS    //
//    +++         //
//                //
//                //
////////////////////


contract MRCOCE is ERC1155Creator {
    constructor() ERC1155Creator("MRC ARTE ONCHAIN EDITIONS", "MRCOCE") {}
}
