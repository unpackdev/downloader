
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Elapsing Time Diary
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//    ╔═╗┌─┐┌─┐┬ ┬┬┌─┐  ╔╗╔┌─┐┌─┐┌─┐┌─┐┌─┐┬ ┬┌─┐    //
//    ╚═╗├─┤│  ├─┤│├┤   ║║║├─┤│ ┬├─┤└─┐├─┤│││├─┤    //
//    ╚═╝┴ ┴└─┘┴ ┴┴└─┘  ╝╚╝┴ ┴└─┘┴ ┴└─┘┴ ┴└┴┘┴ ┴    //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract ETD is ERC721Creator {
    constructor() ERC721Creator("Elapsing Time Diary", "ETD") {}
}
