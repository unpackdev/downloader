// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity 0.8.4;

import "./Initializable.sol";
import "./AddressUpgradeable.sol";

/**
 * @notice A mixin that stores a reference to the Wethio treasury contract.
 */
abstract contract WethioTreasuryNode is Initializable {
    using AddressUpgradeable for address;

    address private treasury;

    /**
     * @dev Called once after the initial deployment to set the Wethio treasury address.
     */
    function _initializeWethioTreasuryNode(address _treasury)
        internal
        initializer
    {
        require(
            _treasury.isContract(),
            "WethioTreasuryNode: Address is not a contract"
        );
        treasury = _treasury;
    }

    /**
     * @notice Returns the address of the Wethio treasury.
     */
    function getWethioTreasury() public view returns (address) {
        return treasury;
    }

    /**
     * @notice Updates the address of the Wethio treasury.
     */
    function _updateWethioTreasury(address _treasury) internal {
        require(
            _treasury.isContract(),
            "WethioTreasuryNode: Address is not a contract"
        );
        treasury = _treasury;
    }

    uint256[1000] private __gap;
}
