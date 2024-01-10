// SPDX-License-Identifier: MIT
/**

 .d8888b.  888      d8b 888          888                             d8b
d88P  Y88b 888      Y8P 888          888                             Y8P
Y88b. d88P 888          888          888
 "Y88888"  88888b.  888 888888       88888b.   .d88b.  88888b.d88b.  888  .d88b.  .d8888b
.d8P""Y8b. 888 "88b 888 888          888 "88b d88""88b 888 "888 "88b 888 d8P  Y8b 88K
888    888 888  888 888 888          888  888 888  888 888  888  888 888 88888888 "Y8888b.
Y88b  d88P 888 d88P 888 Y88b.        888  888 Y88..88P 888  888  888 888 Y8b.          X88
 "Y8888P"  88888P"  888  "Y888       888  888  "Y88P"88888  888  888 888  "Y8888   88888P'
                                                     888
                                                     888
88888b.  888d888  .d88b.  .d8888b   .d88b.  88888b.  888888 .d8888b
888 "88b 888P"   d8P  Y8b 88K      d8P  Y8b 888 "88b 888    88K
888  888 888     88888888 "Y8888b. 88888888 888  888 888    "Y8888b.
888 d88P 888     Y8b.          X88 Y8b.     888  888 Y88b.       X88
88888P"  888      "Y8888   88888P'  "Y8888  888  888  "Y888  88888P'
888
888
8.d8888b.  888      d8b 888           .d8888b.                    888
d88P  Y88b 888      Y8P 888          d88P  Y88b                   888
Y88b. d88P 888          888          888    888                   888
 "Y88888"  88888b.  888 888888       888         .d88b.  88888b.  888888  .d88b.
.d8P""Y8b. 888 "88b 888 888          888  88888 d8P  Y8b 888 "88b 888    d8P  Y8b
888    888 888  888 888 888          888    888 88888888 888  888 888    88888888
Y88b  d88P 888 d88P 888 Y88b.        Y88b  d88P Y8b.     888  888 Y88b.  Y8b.
 "Y8888P"  88888P"  888  "Y888        "Y8888P88  "Y8888  888  888  "Y888  "Y8888
*/

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title Gente
 * Gente - a contract for 8bit Homies, 8bit Gente non-fungible portraits.
 */
contract Gente is ERC721Tradable {
    constructor(address _proxyRegistryAddress)
    ERC721Tradable("8bit Gente", "GENTE", _proxyRegistryAddress)
    {}

    function baseTokenURI() override public pure returns (string memory) {
        return "https://www.lushus.art/collection/1/nft/";
    }
}