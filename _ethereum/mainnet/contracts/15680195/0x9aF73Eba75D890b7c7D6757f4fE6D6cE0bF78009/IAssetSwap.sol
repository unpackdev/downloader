// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./AssetStructsUpgradeable.sol";
import "./AssetEnumsUpgradeable.sol";

/**
 * @title IAssetSwap
 * @author NeatFi
 * @notice Interface to the {AssetSwap} contract of NeatFi Swap module.
 */
interface IAssetSwap {
    /**
     * @notice Makes a Bid for an Order.
     * @dev Record an Order struct of the Bid type. Called only from the NeatFi contract.
          Since this is for Swap Orders, there are no startPrice and endPrice.
     * @param bidder - The address of the bidder.
     * @param tokens - The array of Token assets. 
     * @param listingTime - The timestamp of the Bid creation.
     * @param orderHash - The hash of the Order for which this Bid is being made.
     * @param actorKey - The actor key of an Actor contract.
     * @return bidHash - The hash of the Bid type Order.
     */
    function makeBid(
        address bidder,
        AssetStructsUpgradeable.Token[] calldata tokens,
        uint256 listingTime,
        bytes32 orderHash,
        bytes32 actorKey
    ) external returns (bytes32 bidHash);

    /**
     * @notice Approves and resolves a Swap Order.
     * @dev Called only from the NeatFi contract.
     * @param maker - The address of the Order maker.
     * @param orderHash - The hash of the Order.
     * @param bidHash - The hash of the Bid type Order. This is the Bid type Order that is
     *        accepted by the Order maker.
     * @param orderData - Optional additional data to include with the transaction.
     * @param bidData - Optional additional data to include with the transaction.
     */
    function approveAndResolveSwap(
        address maker,
        bytes32 orderHash,
        bytes32 bidHash,
        bytes calldata orderData,
        bytes calldata bidData
    ) external;
}
