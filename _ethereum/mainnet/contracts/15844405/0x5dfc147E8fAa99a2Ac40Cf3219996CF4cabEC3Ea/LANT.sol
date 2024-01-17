
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: La Antigua
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//     𝕃𝕒 𝔸𝕟𝕥𝕚𝕘𝕦𝕒     //
//                             //
//                             //
/////////////////////////////////


contract LANT is ERC721Creator {
    constructor() ERC721Creator("La Antigua", "LANT") {}
}
