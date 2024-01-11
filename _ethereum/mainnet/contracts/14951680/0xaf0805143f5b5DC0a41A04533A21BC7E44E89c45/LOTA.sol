
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lands of the Arctic
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                           //
//                                                                                           //
//    ##                H|             #H|   #|  ##            #|            #|  #|          //
//    ##   ##|  ##H|    H| #HH|   #H| ##    ##HH|##    #H|    #HH| ## H|#HH|##HH|   #HH|     //
//    ##     H| ## H| #HH|##H|   ## H|##|    #|  ##H| ##HH|  ##  ||##H|##    #|  #|##        //
//    ##   ##H| ## H|## H|   H|  ## H|##     #|  ## H|##     ##HH||##  ##    #|  #|##        //
//    ##HH|##HH|## H| #HH|##H|    #H| ##     #H| ## H| #HH|  ##  ||##   #HH| #H| #H|#HH|     //
//                                                                                           //
//                                                                                           //
//                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////


contract LOTA is ERC721Creator {
    constructor() ERC721Creator("Lands of the Arctic", "LOTA") {}
}
