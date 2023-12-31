// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Honkaku Detectives | chapters
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////
//                    //
//                    //
//    Honkaku v1.0    //
//                    //
//                    //
////////////////////////


contract Honkaku is ERC1155Creator {
    constructor() ERC1155Creator("Honkaku Detectives | chapters", "Honkaku") {}
}
