
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: typoarchive
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    originalworksbytypofranklin.    //
//                                    //
//                                    //
////////////////////////////////////////


contract TFA is ERC721Creator {
    constructor() ERC721Creator("typoarchive", "TFA") {}
}
