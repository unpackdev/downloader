
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ProofOfWorkGallons
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    //////////////////////////////    //
//    //                          //    //
//    //                          //    //
//    //      \           /       //    //
//    //       \         /        //    //
//    //        )       (         //    //
//    //      .`         `.       //    //
//    //    .'             `.     //    //
//    //    :        |       :    //    //
//    //    '.      .'.     .'    //    //
//    //      \`'''`\ /`'''`/     //    //
//    //       \     |     /      //    //
//    //        |    |    |       //    //
//    //                          //    //
//    //                          //    //
//    //////////////////////////////    //
//                                      //
//                                      //
//////////////////////////////////////////


contract POWGS is ERC721Creator {
    constructor() ERC721Creator("ProofOfWorkGallons", "POWGS") {}
}
