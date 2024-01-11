
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Luke Photography
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//                                                    //
//                 __                                 //
//    |     |  _  |__)|_  _ |_ _  _  _ _  _ |_        //
//    |__|_||((-  |   | )(_)|_(_)(_)| (_||_)| )\/     //
//                               _/      |     /      //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract LPHOTO is ERC721Creator {
    constructor() ERC721Creator("Luke Photography", "LPHOTO") {}
}
