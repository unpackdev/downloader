
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



contract CIRCA_CreatedByALIENSWAP is ERC721Creator {
    constructor() ERC721Creator(unicode"CIRCA", unicode"CIRCA", 0x694E5C6c5092025644172fE2081188333960fe24, 1000000, 1000000, "https://createx.art/api/v1/createx/metadata/ETH/qv6n5yb7pmo00a7t1usy51tiuxknss8y/", 
    "https://createx.art/api/v1/createx/collection_url/ETH/qv6n5yb7pmo00a7t1usy51tiuxknss8y", 0x984886312107a9ae23B8290D6C1D519A737283A2, 100, 1697097854, 1000000) {}
}
