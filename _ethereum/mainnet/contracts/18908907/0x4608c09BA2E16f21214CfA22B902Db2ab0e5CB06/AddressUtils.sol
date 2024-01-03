// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "./AddressUpgradeable.sol";

/**
 * @title Dollet AddressUtils library
 * @author Dollet Team
 * @notice A collection of helpers related to the address type.
 */
library AddressUtils {
    using AddressUpgradeable for address;

    error NotContract(address _address);
    error ZeroAddress();

    /**
     * @notice Checks if an address is a contract.
     * @param _address An address to check.
     */
    function onlyContract(address _address) internal view {
        if (!_address.isContract()) revert NotContract(_address);
    }

    /**
     * @notice Checks if an address is not zero address.
     * @param _address An address to check.
     */
    function onlyNonZeroAddress(address _address) internal pure {
        if (_address == address(0)) revert ZeroAddress();
    }

    /**
     * @notice Checks if a token address is a contract or native token.
     * @param _address An address to check.
     */
    function onlyTokenContract(address _address) internal view {
        if (_address == address(0)) return; // ETH
        if (!_address.isContract()) revert NotContract(_address);
    }
}
