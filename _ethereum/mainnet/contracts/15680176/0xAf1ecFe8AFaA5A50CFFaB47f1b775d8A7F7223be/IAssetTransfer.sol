// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./AssetStructsUpgradeable.sol";

/**
 * @title IAssetTransfer
 * @author NeatFi
 * @notice Interface to {AssetTransfer} contract.
 */
interface IAssetTransfer {
    /**
     * @notice Resolves the transfer of assets for a given Order.
     * @dev The calling module should be an approved operator by the corresponding
     *      asset holder contract. This implements the gtransfer of assets according
     *      to IERC20, IERC721, and IERC1155 standard interfaces.
     * @param order - The Order struct which contains the assets to be transferred.
     * @param from - The address of the current asset owner.
     * @param to - The address of the new asset owner.
     * @param data - Optional additional data to include with the transaction.
     */
    function transferResolver(
        AssetStructsUpgradeable.Order memory order,
        address from,
        address to,
        bytes calldata data
    ) external;
}
