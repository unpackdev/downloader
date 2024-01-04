// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./ERC1155Tradable.sol";

contract LootItems is ERC1155Tradable {
    /**
     * @dev Initialize LootItems
     */
    constructor(string memory baseURI, address proxyRegistryAddress)
        public
        ERC1155Tradable("Loot", "ITEMS", proxyRegistryAddress)
    {
        super._setBaseMetadataURI(baseURI);
    }
}
