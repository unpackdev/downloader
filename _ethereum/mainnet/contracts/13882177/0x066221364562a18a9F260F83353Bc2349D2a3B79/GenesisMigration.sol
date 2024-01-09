// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./IERC1155.sol";
import "./ERC1155Receiver.sol";

import "./IMoonChipsERC1155.sol";

struct StoreFrontTokenDto {
    uint256 storeFrontId;
    uint256 moonchipId;
}

contract GenesisMoonChipMigration is ERC1155Receiver, Ownable {

    address storeFrontAddress;
    address moonchipAddress;
    address burnAddress = 0x000000000000000000000000000000000000dEaD;

    // moonchip tokenId map -> storefront tokenId
    mapping(uint256 => uint256) storeFrontTokenMap;

    event LegacyGenesisMigrated(uint256 _legacyStoreFrontId, uint256 _moonchipTokenId);

    constructor(address _storeFrontAddress, address _moonchipAddress) {
        storeFrontAddress = _storeFrontAddress;
        moonchipAddress = _moonchipAddress;
    }

    /**
     * @dev Migrates old storefront tokens to new moonchip token
     * burns old storefront token for its equivalent moonchip token
     * @param _moonchipIds genesis ids e.g. Genesis #15 would be _moonchipId=15
     */
    function migrateGenesisTokens(uint256[] memory _moonchipIds)
        public
    {

        for (uint256 i = 0; i < _moonchipIds.length; i++) {

            uint256 storeFrontTokenId = storeFrontTokenMap[_moonchipIds[i]];
            require(storeFrontTokenId > 0, "could not find a matching storefront token for a provided genesis id");

            require(
                IERC1155(storeFrontAddress).balanceOf(msg.sender, storeFrontTokenId) > 0,
                "could not confirm ownership of legacy genesis storefront token"
            );

            // burn storefront id
            IERC1155(storeFrontAddress).safeTransferFrom(
                msg.sender,
                burnAddress,
                storeFrontTokenId,
                1,
                ''
            );

            // transfer equivalent moonchip token
            IERC1155(moonchipAddress).safeTransferFrom(
                address(this),
                msg.sender,
                _moonchipIds[i],
                1,
                ''
            );

            emit LegacyGenesisMigrated(storeFrontTokenId, _moonchipIds[i]);

        }
    }

    /**
     * @dev sets mapping between old storefront tokenId and new moonchip tokenId
     * @param _storeFrontTokenDto list of mappings to store
     */
    function setStoreFrontTokenMap(StoreFrontTokenDto[] memory _storeFrontTokenDto)
        public
        onlyOwner
    {
        for (uint i = 0; i < _storeFrontTokenDto.length; i++) {
            storeFrontTokenMap[_storeFrontTokenDto[i].moonchipId] = _storeFrontTokenDto[i].storeFrontId;
        }
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

}