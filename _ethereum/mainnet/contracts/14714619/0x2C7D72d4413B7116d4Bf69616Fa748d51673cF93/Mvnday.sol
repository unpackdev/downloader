
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Becky Made Me Do It
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//    #     #                                       //
//    ##   ## #    # #    # #####    ##   #   #     //
//    # # # # #    # ##   # #    #  #  #   # #      //
//    #  #  # #    # # #  # #    # #    #   #       //
//    #     # #    # #  # # #    # ######   #       //
//    #     #  #  #  #   ## #    # #    #   #       //
//    #     #   ##   #    # #####  #    #   #       //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract Mvnday is ERC721Creator {
    constructor() ERC721Creator("Becky Made Me Do It", "Mvnday") {}
}
