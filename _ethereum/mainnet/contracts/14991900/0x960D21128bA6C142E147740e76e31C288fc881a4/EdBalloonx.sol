
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ed Balloon
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////
//                                                                                    //
//                                                                                    //
//     88888888b       dP     888888ba           dP dP                                //
//     88              88     88    `8b          88 88                                //
//    a88aaaa    .d888b88    a88aaaa8P' .d8888b. 88 88 .d8888b. .d8888b. 88d888b.     //
//     88        88'  `88     88   `8b. 88'  `88 88 88 88'  `88 88'  `88 88'  `88     //
//     88        88.  .88     88    .88 88.  .88 88 88 88.  .88 88.  .88 88    88     //
//     88888888P `88888P8     88888888P `88888P8 dP dP `88888P' `88888P' dP    dP     //
//                                                                                    //
//                                                                                    //
//                                                                                    //
//                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////


contract EdBalloonx is ERC721Creator {
    constructor() ERC721Creator("Ed Balloon", "EdBalloonx") {}
}
