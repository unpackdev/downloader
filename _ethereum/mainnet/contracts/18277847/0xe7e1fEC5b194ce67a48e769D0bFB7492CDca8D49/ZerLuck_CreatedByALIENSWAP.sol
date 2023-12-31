
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



contract ZerLuck_CreatedByALIENSWAP is ERC721Creator {
    constructor() ERC721Creator(unicode"Zer0Luck", unicode"zero", 0x694E5C6c5092025644172fE2081188333960fe24, 1, 1, "https://createx.art/api/v1/createx/metadata/ETH/c77esfumdqan1vr5hip8i29tfg8hdkrt/", 
    "https://createx.art/api/v1/createx/collection_url/ETH/c77esfumdqan1vr5hip8i29tfg8hdkrt", 0x9b399D329a3CDfB635817eC73d4117Bf3cC27a39, 300, 1696430816, 1) {}
}
