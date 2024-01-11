
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: art-as-nft
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//    ┌─┐┬─┐┌┬┐  ┌─┐┌─┐   ┌┐┌┌─┐┌┬┐    //
//    ├─┤├┬┘ │───├─┤└─┐───│││├┤  │     //
//    ┴ ┴┴└─ ┴   ┴ ┴└─┘   ┘└┘└   ┴     //
//                                     //
//                                     //
/////////////////////////////////////////


contract NFTart is ERC721Creator {
    constructor() ERC721Creator("art-as-nft", "NFTart") {}
}
