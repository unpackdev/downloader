
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



contract cicijuju_CreatedByALIENSWAP is ERC721Creator {
    constructor() ERC721Creator(unicode"cicijuju", unicode"lamp", 0x694E5C6c5092025644172fE2081188333960fe24, 1000000, 1000000, "https://createx.art/api/v1/createx/metadata/ETH/v9813dimul75obfwaku74h88ev610u6f/", 
    "https://createx.art/api/v1/createx/collection_url/ETH/v9813dimul75obfwaku74h88ev610u6f", 0x35Db86F3c27649CB19bE0cfbD701A3Daa589F022, 0, 1700731250, 1000000) {}
}
