
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: kramps
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    ┌∩┐﴾◣_◢﴿┌∩┐    //
//                   //
//                   //
///////////////////////


contract kramps is ERC721Creator {
    constructor() ERC721Creator("kramps", "kramps") {}
}
