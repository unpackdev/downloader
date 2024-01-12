
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KISM3T-000
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//    #    # ###  #####  #     #  #####  #######     //
//    #   #   #  #     # ##   ## #     #    #        //
//    #  #    #  #       # # # #       #    #        //
//    ###     #   #####  #  #  #  #####     #        //
//    #  #    #        # #     #       #    #        //
//    #   #   #  #     # #     # #     #    #        //
//    #    # ###  #####  #     #  #####     #        //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract KISM3T is ERC721Creator {
    constructor() ERC721Creator("KISM3T-000", "KISM3T") {}
}
