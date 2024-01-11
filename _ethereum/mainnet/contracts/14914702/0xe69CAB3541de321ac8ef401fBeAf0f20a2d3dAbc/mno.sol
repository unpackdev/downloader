
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: monno
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                      //
//                                                                                                      //
//       mmmmmmm    mmmmmmm      ooooooooooo   nnnn  nnnnnnnn    nnnn  nnnnnnnn       ooooooooooo       //
//     mm:::::::m  m:::::::mm  oo:::::::::::oo n:::nn::::::::nn  n:::nn::::::::nn   oo:::::::::::oo     //
//    m::::::::::mm::::::::::mo:::::::::::::::on::::::::::::::nn n::::::::::::::nn o:::::::::::::::o    //
//    m::::::::::::::::::::::mo:::::ooooo:::::onn:::::::::::::::nnn:::::::::::::::no:::::ooooo:::::o    //
//    m:::::mmm::::::mmm:::::mo::::o     o::::o  n:::::nnnn:::::n  n:::::nnnn:::::no::::o     o::::o    //
//    m::::m   m::::m   m::::mo::::o     o::::o  n::::n    n::::n  n::::n    n::::no::::o     o::::o    //
//    m::::m   m::::m   m::::mo::::o     o::::o  n::::n    n::::n  n::::n    n::::no::::o     o::::o    //
//    m::::m   m::::m   m::::mo::::o     o::::o  n::::n    n::::n  n::::n    n::::no::::o     o::::o    //
//    m::::m   m::::m   m::::mo:::::ooooo:::::o  n::::n    n::::n  n::::n    n::::no:::::ooooo:::::o    //
//    m::::m   m::::m   m::::mo:::::::::::::::o  n::::n    n::::n  n::::n    n::::no:::::::::::::::o    //
//    m::::m   m::::m   m::::m oo:::::::::::oo   n::::n    n::::n  n::::n    n::::n oo:::::::::::oo     //
//    mmmmmm   mmmmmm   mmmmmm   ooooooooooo     nnnnnn    nnnnnn  nnnnnn    nnnnnn   ooooooooooo       //
//                                                                                                      //
//                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////


contract mno is ERC721Creator {
    constructor() ERC721Creator("monno", "mno") {}
}
