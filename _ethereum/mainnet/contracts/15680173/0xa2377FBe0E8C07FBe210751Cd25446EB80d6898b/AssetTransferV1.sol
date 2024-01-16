// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./AssetTransferOperationsUpgradeable.sol";
import "./UUPSUpgradeable.sol";

/**
 * @title AssetTransferV1
 * @author NeatFi
 * @notice This contract holds the external operations for asset transfer within NeatFi.
 */
contract AssetTransferV1 is
    AssetTransferOperationsUpgradeable,
    UUPSUpgradeable
{
    string private name;
    string private currentVersion;

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
     * @dev Resolves the transfer of Token assets.
     * @param order - The Order struct.
     * @param from - The address of the current owner of the asset.
     * @param to - The address of the new owner of the asset.
     * @param data - Optional additional data to include with the transaction.
     */
    function transferResolver(
        Order memory order,
        address from,
        address to,
        bytes calldata data
    ) external onlyRole(AUTHORIZED_OPERATOR) {
        _transferResolver(order, from, to, data);
    }

    /** Initializers */

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(PROTOCOL_ADMIN)
    {}

    function initialize(address neatFiProtocolStorageAddress)
        public
        initializer
        onlyProxy
    {
        __UUPSUpgradeable_init();
        __AssetTransferOperations_init(neatFiProtocolStorageAddress);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        name = "NeatFi Asset Transfer Resolver";
        _setVersion("1.0.0");
    }
}
