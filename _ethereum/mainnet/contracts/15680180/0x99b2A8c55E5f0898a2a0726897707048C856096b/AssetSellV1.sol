// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./AssetSellOperationsUpgradeable.sol";
import "./UUPSUpgradeable.sol";

/**
 * @title AssetSellV1
 * @author NeatFi
 * @notice This contract implements the external facing functionality
 *         for the Asset Sell module of NeatFi.
 */
contract AssetSellV1 is AssetSellOperationsUpgradeable, UUPSUpgradeable {
    string internal name;
    string internal currentVersion;

    /**
     * @dev Sets the version for the current implementation of this contract.
     */
    function _setVersion(string memory newVersion) internal {
        currentVersion = newVersion;
    }

    /**
     * @dev Updates the NeatFi Protocol storage address. Can be executed by a
     *      Protocol Admin only.
     */
    function updateNeatFiProtocolStorageAddress(
        address newNeatFiProtocolStorage
    ) external onlyRole(PROTOCOL_ADMIN) {
        _updateNeatFiProtocolStorageAddress(newNeatFiProtocolStorage);
    }

    /**
     * @dev Updates the Asset Transfer contract address. Can be executed by a
     *      Protocol Admin only.
     */
    function updateAssetTransferAddress(address newAssetTransfer)
        external
        onlyRole(PROTOCOL_ADMIN)
    {
        _updateAssetTransferAddress(newAssetTransfer);
    }

    /**
     * @dev An external function to instantly buy an Order. Handles the
     *      transfer of the Token assets in the Order to the buyer. Can
     *      be called from the NeatFi contract only.
     * @param orderHash - The hash of the Order.
     * @param purchaseValue - The end price of the Order, in native tokens.
     * @param buyer - The address of the buyer.
     * @param data - Optional additional data to include with the transaction.
     */
    function buyItNow(
        bytes32 orderHash,
        uint256 purchaseValue,
        address buyer,
        bytes calldata data
    ) external onlyRole(AUTHORIZED_OPERATOR) {
        _buyItNow(orderHash, purchaseValue, buyer, data);
    }

    /** Initializers */

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(PROTOCOL_ADMIN)
    {}

    function initialize(
        address neatFiProtocolStorageAddress,
        address assetTransferAddress
    ) public initializer onlyProxy {
        __UUPSUpgradeable_init();
        __AssetSellOperations_init(
            assetTransferAddress,
            neatFiProtocolStorageAddress
        );

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        name = "NeatFi Asset Sell Module";
        _setVersion("1.0.0");
    }
}
