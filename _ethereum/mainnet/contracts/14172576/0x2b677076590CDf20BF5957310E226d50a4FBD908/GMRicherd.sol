
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GM Studios Test101
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//    Testing manifold studio smart contract by GM Studios    //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract GMRicherd is ERC721Creator {
    constructor() ERC721Creator("GM Studios Test101", "GMRicherd") {}
}
