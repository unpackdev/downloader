// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CCL 3D Wallet
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//         ##     ##     #######  #######  ##  ##    //
//               ####    #   ##   #   ##   ##  ##    //
//        ###   ##  ##      ##       ##    ##  ##    //
//         ##   ##  ##     ##       ##      ####     //
//         ##   ######    ##       ##        ##      //
//     ##  ##   ##  ##   ##    #  ##    #    ##      //
//     ##  ##   ##  ##   #######  #######   ####     //
//      ####                                         //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract CCLW is ERC721Creator {
    constructor() ERC721Creator("CCL 3D Wallet", "CCLW") {}
}
