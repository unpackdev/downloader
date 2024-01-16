// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Initializable.sol";

/**
 * @title AssetStorageSettingsUpgradeable
 * @author NeatFi
 * @notice This contract holds the protocol storage settings of NeatFi.
 */
contract AssetStorageSettingsUpgradeable is Initializable {
    // Controller of maximum numbers of unique Tokens in an Order.
    uint256 public maxTokenNumber;

    /**
     *
     * @dev Regulates the maximum number of unique Token assets in an Order.
     * @param newMaxTokenNumber - new maximum number of Token assets.
     */
    function _setMaxTokenNumber(uint256 newMaxTokenNumber) internal {
        maxTokenNumber = newMaxTokenNumber;
    }

    /* Initializers */

    function __AssetStorageSettings_init(uint256 newMaxTokenNumber)
        internal
        initializer
    {
        __AssetStorageSettings_init_unchained(newMaxTokenNumber);
    }

    function __AssetStorageSettings_init_unchained(uint256 newMaxTokenNumber)
        internal
        initializer
    {
        _setMaxTokenNumber(newMaxTokenNumber);
    }
}
