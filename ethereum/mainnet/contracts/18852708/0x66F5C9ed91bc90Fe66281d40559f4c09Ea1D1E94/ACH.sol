// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Achromic
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////
//                                                                              //
//                                                                              //
//      ###      ####    ##  ##  ######    #####   ##   ##   ######    ####     //
//     ## ##    ##  ##   ##  ##   ##  ##  ### ###  ### ###     ##     ##  ##    //
//    ##   ##  ##        ##  ##   ##  ##  ##   ##  #######     ##    ##         //
//    ##   ##  ##        ######   #####   ##   ##  ## # ##     ##    ##         //
//    #######  ##        ##  ##   ## ##   ##   ##  ##   ##     ##    ##         //
//    ##   ##   ##  ##   ##  ##   ## ##   ### ###  ##   ##     ##     ##  ##    //
//    ##   ##    ####    ##  ##  #### ##   #####   ### ###   ######    ####     //
//                                                                              //
//                                                                              //
//                                                                              //
//////////////////////////////////////////////////////////////////////////////////


contract ACH is ERC721Creator {
    constructor() ERC721Creator("Achromic", "ACH") {}
}
