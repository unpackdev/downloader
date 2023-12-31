// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Custom Commoners
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    ////////////////////////////    //
//    //                        //    //
//    //                        //    //
//    //    Custom Commoners    //    //
//    //                        //    //
//    //                        //    //
//    ////////////////////////////    //
//                                    //
//                                    //
////////////////////////////////////////


contract CustomCommoners is ERC721Creator {
    constructor() ERC721Creator("Custom Commoners", "CustomCommoners") {}
}
