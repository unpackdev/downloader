// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Hidden Gem
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////
//                                                                                  //
//                                                                                  //
//      ^    ^    ^       ^    ^    ^    ^    ^    ^       ^    ^    ^              //
//     /T\  /h\  /e\     /H\  /i\  /d\  /d\  /e\  /n\     /G\  /e\  /m\             //
//    <___><___><___>   <___><___><___><___><___><___>   <___><___><___>            //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////


contract GEM is ERC721Creator {
    constructor() ERC721Creator("The Hidden Gem", "GEM") {}
}
