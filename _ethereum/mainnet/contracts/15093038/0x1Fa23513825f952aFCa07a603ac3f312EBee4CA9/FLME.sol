
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FLUME
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//     (    (           *             //
//     )\ ) )\ )      (  `            //
//    (()/((()/(   (  )\))(  (        //
//     /(_))/(_))  )\((_)()\ )\       //
//    (_))_(_)) _ ((_|_()((_|(_)      //
//    | |_ | | | | | |  \/  | __|     //
//    | __|| |_| |_| | |\/| | _|      //
//    |_|  |____\___/|_|  |_|___|     //
//                                    //
//    by Andrew Mitchell              //
//                                    //
//                                    //
////////////////////////////////////////


contract FLME is ERC721Creator {
    constructor() ERC721Creator("FLUME", "FLME") {}
}
