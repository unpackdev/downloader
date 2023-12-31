
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



contract YEEE_CreatedByALIENSWAP is ERC721Creator {
    constructor() ERC721Creator(unicode"YEEE", unicode"YRK", 0x694E5C6c5092025644172fE2081188333960fe24, 1000000, 1000000, "https://createx.art/api/v1/createx/metadata/ETH/oqem3tebcmmteyp6l0u76a95dqj7r01u/", 
    "https://createx.art/api/v1/createx/collection_url/ETH/oqem3tebcmmteyp6l0u76a95dqj7r01u", 0x9fdF090D891817Ae7D79477e273DDDFf4D7C9b1D, 100, 1697046347, 1000000) {}
}
