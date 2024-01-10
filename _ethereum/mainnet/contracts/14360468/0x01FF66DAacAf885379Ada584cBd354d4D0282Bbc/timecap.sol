
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Time Capsules
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


contract timecap is ERC721Creator {
    constructor() ERC721Creator("Time Capsules", "timecap") {}
}
