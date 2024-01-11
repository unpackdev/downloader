
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: neontomo
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    ┌┐┌┌─┐┌─┐┌┐┌┌┬┐┌─┐┌┬┐┌─┐    //
//    │││├┤ │ ││││ │ │ │││││ │    //
//    ┘└┘└─┘└─┘┘└┘ ┴ └─┘┴ ┴└─┘    //
//                                //
//                                //
////////////////////////////////////


contract tomo is ERC721Creator {
    constructor() ERC721Creator("neontomo", "tomo") {}
}
