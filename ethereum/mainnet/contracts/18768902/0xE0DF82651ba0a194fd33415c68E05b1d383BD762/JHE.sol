// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JOHN HAMON - EDITION
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////
//                            //
//                            //
//    JOHN HAMON - EDITION    //
//                            //
//                            //
////////////////////////////////


contract JHE is ERC1155Creator {
    constructor() ERC1155Creator("JOHN HAMON - EDITION", "JHE") {}
}
