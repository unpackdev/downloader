// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: oatmeal! editions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//    celebrating the nothing-special days    //
//                                            //
//                                            //
////////////////////////////////////////////////


contract oat is ERC721Creator {
    constructor() ERC721Creator("oatmeal! editions", "oat") {}
}
