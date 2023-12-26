// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ethereal Resilience
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    ┓     •     ┏┓     ┓    //
//    ┣┓┓┏  ┓┏┳┓┏┓┃┫┓┏┏┓┏┫    //
//    ┗┛┗┫  ┗┛┗┗┣┛┗┛┗┻┛┗┗┻    //
//       ┛      ┛             //
//                            //
//                            //
////////////////////////////////


contract ETRES is ERC721Creator {
    constructor() ERC721Creator("Ethereal Resilience", "ETRES") {}
}
