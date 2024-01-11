
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Twenty Duce x Mad Keys
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////
//                                                              //
//                                                              //
//      #####    ###      #    # ####### #     #  #####         //
//     #     #  #   #     #   #  #        #   #  #     #        //
//           # #     #    #  #   #         # #   #              //
//      #####  #     #    ###    #####      #     #####         //
//     #       #     #    #  #   #          #          #        //
//     #        #   #     #   #  #          #    #     #        //
//     #######   ###      #    # #######    #     #####         //
//                                                              //
//                                                              //
//                                                              //
//////////////////////////////////////////////////////////////////


contract PNB is ERC721Creator {
    constructor() ERC721Creator("Twenty Duce x Mad Keys", "PNB") {}
}
