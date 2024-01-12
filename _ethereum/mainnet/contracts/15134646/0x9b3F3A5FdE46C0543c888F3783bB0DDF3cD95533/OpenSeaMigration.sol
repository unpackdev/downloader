// SPDX-License-Identifier: MIT
// OpenSeaMigration v1.1.2
// Creator: LaLa Labs

pragma solidity ^0.8.14;

import "./IERC1155.sol";
import "./ERC1155Receiver.sol";

contract OpenSeaMigration is ERC1155Receiver {
    address public constant BURN_ADDRESS = address(0x000000000000000000000000000000000000dEaD);

    IERC1155 public immutable OPENSEA_STORE;

    uint160 internal immutable MAKER;

    event TokenMigrated(address account, uint256 legacyTokenId, uint256 amount);

    constructor(
        address openSeaStoreAddress,
        address makerAddress
    ) {
        OPENSEA_STORE = IERC1155(openSeaStoreAddress);
        MAKER = uint160(makerAddress);
    }

    // migration of a single token
    function onERC1155Received(
        address /* operator */,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        require(msg.sender == address(OPENSEA_STORE), 'OSMigration: Only accepting OpenSea assets');

        _migrateLegacyToken(from, id, value, data);
        return IERC1155Receiver.onERC1155Received.selector;
    }

    // migration of multiple tokens
    function onERC1155BatchReceived(
        address /* operator */,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        require(msg.sender == address(OPENSEA_STORE), 'OSMigration: Only accepting OpenSea assets');

        for (uint256 i; i < ids.length; i++) {
            _migrateLegacyToken(from, ids[i], values[i], data);
        }
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @notice Migrates an OpenSea token. The legacy token must have been transferred to this contract before.
     * This method must only be called from `onERC1155Received` or `onERC1155BatchReceived`.
     */
    function _migrateLegacyToken(
        address owner,
        uint256 legacyTokenId,
        uint256 amount,
        bytes calldata data
    ) internal {
        uint256 internalTokenId = _getInternalTokenId(legacyTokenId);

        _onMigrateLegacyToken(owner, legacyTokenId, internalTokenId, amount, data);

        emit TokenMigrated(owner, legacyTokenId, amount);
    }

    /**
     * @dev Overwrite this method to perform the actual migration logic like sending to burn address and minting a new token.
     *   If a token should not/can not be migrated for any reason, revert this call.
     *
     * @param owner The previous owner of the legacy token.
     * @param legacyTokenId The OpenSea token ID
     * @param internalTokenId The internal token ID from the OpenSea collection. This number is incrementing with
     *   every minted token by {MAKER}.
     * @param amount The amount of legacy tokens being migrated.
     * @param data Additional data with no specified format
     */
    function _onMigrateLegacyToken(
        address owner,
        uint256 legacyTokenId,
        uint256 internalTokenId,
        uint256 amount,
        bytes calldata data
    ) internal virtual {
        revert('OSMigration: Not implemented');
    }

    /**
     * @dev Burn the token. Since OpenSea Shared Storefront does not support real burn, transfer to dead address.
     *
     * @param legacyTokenId The OpenSea token ID
     * @param amount The amount of legacy tokens being migrated.
     */
    function _burn(
        uint256 legacyTokenId,
        uint256 amount
    ) internal {
        OPENSEA_STORE.safeTransferFrom(address(this), BURN_ADDRESS, legacyTokenId, amount, "");
    }

    /**
     * @dev Transfer to MAKER. An alternative way for burning, which allows the MAKER to make updates to the metadata,
     *   unless it has been frozen before. Useful to change the NFT image to a blank one for example.
     *
     * @param legacyTokenId The OpenSea token ID
     * @param amount The amount of legacy tokens being migrated.
     * @param data Additional data with no specified format
     */
    function _transferToMaker(
        uint256 legacyTokenId,
        uint256 amount,
        bytes calldata data
    ) internal {
        OPENSEA_STORE.safeTransferFrom(address(this), address(MAKER), legacyTokenId, amount, data);
    }

    /**
     * Retrieves the internal token ID from a legacy token ID in OpenSea format.
     * - Requires the format of the legacyTokenId to match OpenSea format
     * - Requires the encoded maker address to be the original minter
     *
     * @return The OpenSea internal token ID.
     *
     * Thanks CyberKongz for the insights into OpenSea IDs!
     */
    function _getInternalTokenId(uint256 legacyTokenId) public view returns (uint256) {
        // first 20 bytes: check maker address
        if (uint160(legacyTokenId >> 96) != MAKER) {
            revert('OSMigration: Invalid Maker');
        }

        // last 5 bytes: should always be 1
        if (legacyTokenId & 0x000000000000000000000000000000000000000000000000000000ffffffffff != 1) {
            revert('OSMigration: Invalid Checksum');
        }

        // middle 7 bytes: nft id (serial for all NFTs that MAKER minted)
        return (legacyTokenId & 0x0000000000000000000000000000000000000000ffffffffffffff0000000000) >> 40;
    }
}
