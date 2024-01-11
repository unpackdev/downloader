
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./ERC1155Creator.sol";

////////////////
//            //
//            //
//    -=    //
//            //
//            //
////////////////


contract NFTGM is ERC1155Creator {
    constructor() ERC1155Creator("https://api-testnet.blockcreateart.co/api/v1/nftgm/metadata/eth/62a1a8fc2d06ec61ad9f0b69/") {}
}
