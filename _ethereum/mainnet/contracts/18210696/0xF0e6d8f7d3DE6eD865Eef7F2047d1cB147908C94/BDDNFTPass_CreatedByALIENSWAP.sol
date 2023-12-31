
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



contract BDDNFTPass_CreatedByALIENSWAP is ERC721Creator {
    constructor() ERC721Creator(unicode"BDD NFT Pass", unicode"BDD NFT Tickets", 0x694E5C6c5092025644172fE2081188333960fe24, 300, 300, "https://createx.art/api/v1/createx/metadata/ETH/dn4v4tchlln2faw3l6t4pp1ux7ij0nie/", 
    "https://createx.art/api/v1/createx/collection_url/ETH/dn4v4tchlln2faw3l6t4pp1ux7ij0nie", 0x2d1F154666cC71824500a905A27ead1C9a9cc5Ce, 100, 1695643237, 300) {}
}
