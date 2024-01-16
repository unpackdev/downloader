// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Initializable.sol";

/**
 * @title AssetSwapStorageUpgradeable
 * @author NeatFi
 * @notice This contract holds the storage for the Asset Swap
 *         module of Neatfi.
 */
contract AssetSwapStorageUpgradeable is Initializable {
    /**
     * @dev Maps the Bid type Order hashes to their Order hash.
     */
    mapping(bytes32 => bytes32[]) public bidsByOrder;

    /**
     * @dev Records the escrow parties by mapping the Order hash
     *      to the Bid hash.
     */
    mapping(bytes32 => bytes32) public swapEscrowParties;

    /** Initializers */

    function __AssetSwapStorage_init() internal initializer {
        __AssetSwapStorage_init_unchained();
    }

    function __AssetSwapStorage_init_unchained() internal initializer {}
}
