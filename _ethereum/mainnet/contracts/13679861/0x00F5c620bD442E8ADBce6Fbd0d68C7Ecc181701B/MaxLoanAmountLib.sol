// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Libraries
import "./CacheLib.sol";

// Storage
import "./app.sol";

/**
 * @notice Utility library of inline functions for MaxLoanAmount asset setting.
 *
 * @author develop@teller.finance
 */
library MaxLoanAmountLib {
    bytes32 private constant NAME = keccak256("MaxLoanAmount");

    function s(address asset) private view returns (Cache storage) {
        return AppStorageLib.store().assetSettings[asset];
    }

    function get(address asset) internal view returns (uint256) {
        return s(asset).uints[NAME];
    }

    function set(address asset, uint256 newValue) internal {
        s(asset).uints[NAME] = newValue;
    }
}
