// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @title IAssetSell
 * @author NeatFi
 * @notice Interface to the {AssetSell} contract of NeatFi Sell module.
 */
interface IAssetSell {
    /**
     * @notice Buys the assets of a Sell Order for native tokens (i.e. Eth for Ethereum).
     * @dev Called only from the NeatFi contract.
     * @param orderHash - The hash of the Order.
     * @param purchaseValue - The purchase value in native tokens.
     * @param buyer - The address of the buyer.
     * @param data - Optional additional data to include with the transaction.
     */
    function buyItNow(
        bytes32 orderHash,
        uint256 purchaseValue,
        address buyer,
        bytes calldata data
    ) external;
}
