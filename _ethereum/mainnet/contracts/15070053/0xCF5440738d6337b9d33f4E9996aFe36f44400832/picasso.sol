
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: picassoocean
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////
//             //
//             //
//    毕加索的海    //
//             //
//             //
/////////////////


contract picasso is ERC721Creator {
    constructor() ERC721Creator("picassoocean", "picasso") {}
}
