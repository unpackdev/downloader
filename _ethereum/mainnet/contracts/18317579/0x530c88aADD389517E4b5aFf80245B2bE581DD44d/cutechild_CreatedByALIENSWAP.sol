
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



contract cutechild_CreatedByALIENSWAP is ERC721Creator {
    constructor() ERC721Creator(unicode"cute child", unicode"eth", 0x694E5C6c5092025644172fE2081188333960fe24, 10000, 10000, "https://createx.art/api/v1/createx/metadata/ETH/zsjpzys7ig7ib8kxst1teekx9gdgx1cc/", 
    "https://createx.art/api/v1/createx/collection_url/ETH/zsjpzys7ig7ib8kxst1teekx9gdgx1cc", 0x4053ff83cCAC6506129506e2a5bC3A2cAcD8E7f3, 300, 1696910986, 10000) {}
}
