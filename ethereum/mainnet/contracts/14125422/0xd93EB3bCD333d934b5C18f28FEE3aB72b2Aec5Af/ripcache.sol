
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ripcache
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                                    _              //
//     _ ___ _ _ __   ____ __ _  ____| |___  ___     //
//    | '__/| | '_ \ / __/  _' |/ __/| '_  \/ _ \    //
//    | |   | | |_) | (__| (_| | (__ | | | |  __/    //
//    |_|   |_| .__/ \___/\__,_|\___/|_| |_|\___|    //
//            |_|                                    //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract ripcache is ERC721Creator {
    constructor() ERC721Creator("ripcache", "ripcache") {}
}
