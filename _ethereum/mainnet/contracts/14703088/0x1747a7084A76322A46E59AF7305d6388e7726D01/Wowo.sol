
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 0xWowo
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//      ###          #     #                          //
//     #   #  #    # #  #  #  ####  #    #  ####      //
//    #     #  #  #  #  #  # #    # #    # #    #     //
//    #     #   ##   #  #  # #    # #    # #    #     //
//    #     #   ##   #  #  # #    # # ## # #    #     //
//     #   #   #  #  #  #  # #    # ##  ## #    #     //
//      ###   #    #  ## ##   ####  #    #  ####      //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract Wowo is ERC721Creator {
    constructor() ERC721Creator("0xWowo", "Wowo") {}
}
