
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



contract XXXself_CreatedByALIENSWAP is ERC721Creator {
    constructor() ERC721Creator(unicode"XXX self", unicode"XXX", 0x694E5C6c5092025644172fE2081188333960fe24, 1000, 1000, "https://createx.art/api/v1/createx/metadata/ETH/1v2i2x1blda9hh0zvrzzo9s2wipsluqg/", 
    "https://createx.art/api/v1/createx/collection_url/ETH/1v2i2x1blda9hh0zvrzzo9s2wipsluqg", 0x16F1994a89859D6E565C791829723b68B3B30CB3, 20, 1696947078, 1000) {}
}
