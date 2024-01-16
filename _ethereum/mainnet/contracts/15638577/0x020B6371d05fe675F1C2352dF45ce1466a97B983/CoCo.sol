
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Coincidental Collabs
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//                                         //
//    ╔═╗┌┐┌┌─┐╔╗ ┬  ┌─┐┌─┐┬┌─╔═╗┌─┐┌┬┐    //
//    ║ ║│││├┤ ╠╩╗│  ├─┤│  ├┴┐║  ├─┤ │     //
//    ╚═╝┘└┘└─┘╚═╝┴─┘┴ ┴└─┘┴ ┴╚═╝┴ ┴ ┴     //
//                                         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract CoCo is ERC721Creator {
    constructor() ERC721Creator("Coincidental Collabs", "CoCo") {}
}
