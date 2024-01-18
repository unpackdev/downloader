
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ProofOfWorkGallon
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//      \           /       //
//       \         /        //
//        )       (         //
//      .`         `.       //
//    .'             `.     //
//    :        |       :    //
//    '.      .'.     .'    //
//      \`'''`\ /`'''`/     //
//       \     |     /      //
//        |    |    |       //
//                          //
//                          //
//////////////////////////////


contract POWG is ERC721Creator {
    constructor() ERC721Creator("ProofOfWorkGallon", "POWG") {}
}
