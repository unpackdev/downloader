// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bykowladimir
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    Bykowladimir    //
//                    //
//                    //
////////////////////////


contract Bykowladimir is ERC721Creator {
    constructor() ERC721Creator("Bykowladimir", "Bykowladimir") {}
}
