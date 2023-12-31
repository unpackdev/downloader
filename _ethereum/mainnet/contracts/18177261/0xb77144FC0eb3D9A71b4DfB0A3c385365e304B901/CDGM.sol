// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cologne Dude GM
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//     ___     _                    ___        _         //
//    |  _>___| |___  ___._ _ ___  | . \ _ _ _| |___     //
//    | <_/ . \ / . \/ . | ' / ._> | | || | / . / ._>    //
//    `___|___/_\___/\_. |_|_\___. |___/`___\___\___.    //
//                   <___'                               //
//                                                       //
//                                                       //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract CDGM is ERC1155Creator {
    constructor() ERC1155Creator("Cologne Dude GM", "CDGM") {}
}
