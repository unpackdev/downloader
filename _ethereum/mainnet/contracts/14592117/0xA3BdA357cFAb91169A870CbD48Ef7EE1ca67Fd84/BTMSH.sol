
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BATMASH
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//    #####    ##   ##### #    #   ##    ####  #    #     //
//    #    #  #  #    #   ##  ##  #  #  #      #    #     //
//    #####  #    #   #   # ## # #    #  ####  ######     //
//    #    # ######   #   #    # ######      # #    #     //
//    #    # #    #   #   #    # #    # #    # #    #     //
//    #####  #    #   #   #    # #    #  ####  #    #     //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract BTMSH is ERC721Creator {
    constructor() ERC721Creator("BATMASH", "BTMSH") {}
}
