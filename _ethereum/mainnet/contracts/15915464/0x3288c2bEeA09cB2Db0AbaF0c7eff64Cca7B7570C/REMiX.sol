
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MAiWORLD REMiXES
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    MAiWORLD REMiXES    //
//                        //
//                        //
////////////////////////////


contract REMiX is ERC721Creator {
    constructor() ERC721Creator("MAiWORLD REMiXES", "REMiX") {}
}
