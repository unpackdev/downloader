
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/////////////////////////////////////////////////////////
//    all-in-one NFT generator at https://nftgm.art    //
/////////////////////////////////////////////////////////

import "./ERC1155Creator.sol";

//////////////
//  BCANYC  //
//////////////


contract BCALabsNYC is ERC1155Creator {
    constructor() ERC1155Creator("https://api.nftgm.art/api/v1/nftgm/metadata/eth/62b34cab42e5dc1cf222c238/") {}
}
