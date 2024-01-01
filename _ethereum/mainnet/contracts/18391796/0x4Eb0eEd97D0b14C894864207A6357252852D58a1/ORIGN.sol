// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Origins
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//      e88 88e          ,e,          ,e,                   //
//     d888 888b  888,8,  "   e88 888  "  888 8e   dP"Y     //
//    C8888 8888D 888 "  888 d888 888 888 888 88b C88b      //
//     Y888 888P  888    888 Y888 888 888 888 888  Y88D     //
//      "88 88"   888    888  "88 888 888 888 888 d,dP      //
//                             ,  88P                       //
//                            "8",P"                        //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract ORIGN is ERC721Creator {
    constructor() ERC721Creator("Origins", "ORIGN") {}
}
