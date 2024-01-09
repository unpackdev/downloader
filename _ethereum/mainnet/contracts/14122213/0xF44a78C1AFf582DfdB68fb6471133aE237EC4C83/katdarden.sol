
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Memedoll Show
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//                                                        //
//      ^    ^    ^       ^    ^    ^    ^    ^    ^      //
//     /K\  /a\  /t\     /D\  /a\  /r\  /d\  /e\  /n\     //
//    <___><___><___>   <___><___><___><___><___><___>    //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract katdarden is ERC721Creator {
    constructor() ERC721Creator("Memedoll Show", "katdarden") {}
}
