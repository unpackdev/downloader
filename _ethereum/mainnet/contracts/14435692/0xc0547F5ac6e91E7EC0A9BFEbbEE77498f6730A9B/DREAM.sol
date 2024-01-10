
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ALL DAY DREAMERS by Manuel Larino
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//      __    _     _         ___    __    _               //
//     / /\  | |   | |       | | \  / /\  \ \_/            //
//    /_/--\ |_|__ |_|__     |_|_/ /_/--\  |_|             //
//     ___   ___   ____   __    _      ____  ___   __      //
//    | | \ | |_) | |_   / /\  | |\/| | |_  | |_) ( (`     //
//    |_|_/ |_| \ |_|__ /_/--\ |_|  | |_|__ |_| \ _)_)     //
//                     ~                                   //
//    by   |_ /\ /? | |\| ()                               //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract DREAM is ERC721Creator {
    constructor() ERC721Creator("ALL DAY DREAMERS by Manuel Larino", "DREAM") {}
}
