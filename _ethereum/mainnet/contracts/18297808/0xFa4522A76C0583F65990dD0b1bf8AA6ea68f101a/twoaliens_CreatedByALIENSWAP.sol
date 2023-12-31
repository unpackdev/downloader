
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



contract twoaliens_CreatedByALIENSWAP is ERC721Creator {
    constructor() ERC721Creator(unicode"twoaliens", unicode"2a", 0x694E5C6c5092025644172fE2081188333960fe24, 1000000, 1000000, "https://createx.art/api/v1/createx/metadata/ETH/zmzi34cvc22f3mnozu2eyphbncx148o1/", 
    "https://createx.art/api/v1/createx/collection_url/ETH/zmzi34cvc22f3mnozu2eyphbncx148o1", 0xEd1781C7CA946a97Bd87437bB9BBD296f4f4C33e, 1000, 1696672051, 1000000) {}
}
