
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Robot Love Coffee
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//                                        //
//    eeeee  eeeee eeeee  eeeee eeeee     //
//    8   8  8  88 8   8  8  88   8       //
//    8eee8e 8   8 8eee8e 8   8   8e      //
//    88   8 8   8 88   8 8   8   88      //
//    88   8 8eee8 88eee8 8eee8   88      //
//                                        //
//                                        //
//    e     eeeee ee   e eeee             //
//    8     8  88 88   8 8                //
//    8e    8   8 88  e8 8eee             //
//    88    8   8  8  8  88               //
//    88eee 8eee8  8ee8  88ee             //
//                                        //
//                                        //
//    eeee eeeee eeee eeee eeee eeee      //
//    8  8 8  88 8    8    8    8         //
//    8e   8   8 8eee 8eee 8eee 8eee      //
//    88   8   8 88   88   88   88        //
//    88e8 8eee8 88   88   88ee 88ee      //
//                                        //
//                                        //
////////////////////////////////////////////


contract robotlovecoffee is ERC721Creator {
    constructor() ERC721Creator("Robot Love Coffee", "robotlovecoffee") {}
}
