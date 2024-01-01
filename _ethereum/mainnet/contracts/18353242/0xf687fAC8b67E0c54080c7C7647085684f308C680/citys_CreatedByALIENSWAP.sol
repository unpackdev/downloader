
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/////////////////////////////////////////////////////////
//  all-in-one NFT generator at https://alienswap.xyz  //
/////////////////////////////////////////////////////////

import "./ERC721Creator.sol";



///////////////////////////////////////////////////
//   ___  _ _                                    //
//  / _ \| (_)                                   //
// / /_\ \ |_  ___ _ __  _____      ____ _ _ __  //
// |  _  | | |/ _ \ '_ \/ __\ \ /\ / / _` | '_ \ //
// | | | | | |  __/ | | \__ \ V  V / (_| | |_) |//
// \_| |_/_|_|\___|_| |_|___/ \_/\_/ \__,_| .__/ //
//                                        | |    //
//                                        |_|    //
///////////////////////////////////////////////////



contract citys_CreatedByALIENSWAP is ERC721Creator {
    constructor() ERC721Creator(unicode"citys", unicode"citys", 0x694E5C6c5092025644172fE2081188333960fe24, 1000000, 1000000, "https://createx.art/api/v1/createx/metadata/ETH/kpxihaj10aamuh9g7i19xc64u07pb6h3/", 
    "https://createx.art/api/v1/createx/collection_url/ETH/kpxihaj10aamuh9g7i19xc64u07pb6h3", 0xb9555Cd0d5409f58a2fc029F8785A93Baa6805A4, 2, 1697342257, 1000000) {}
}
