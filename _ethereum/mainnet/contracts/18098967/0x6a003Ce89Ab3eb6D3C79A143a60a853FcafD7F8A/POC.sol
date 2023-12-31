// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: POC (proof of charity)
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////
//                     //
//                     //
//    POCRISASTUDIO    //
//                     //
//                     //
/////////////////////////


contract POC is ERC1155Creator {
    constructor() ERC1155Creator("POC (proof of charity)", "POC") {}
}
