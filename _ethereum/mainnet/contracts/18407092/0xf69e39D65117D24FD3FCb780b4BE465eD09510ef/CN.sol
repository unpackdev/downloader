// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Chromory /Nira Collaboration Edition
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//    Chromory /Nira Collaboration Edition    //
//                                            //
//                                            //
////////////////////////////////////////////////


contract CN is ERC1155Creator {
    constructor() ERC1155Creator("Chromory /Nira Collaboration Edition", "CN") {}
}
