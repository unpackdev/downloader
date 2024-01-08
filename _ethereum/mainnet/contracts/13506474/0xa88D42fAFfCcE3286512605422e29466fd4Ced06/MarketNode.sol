// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity 0.8.4;

import "./Initializable.sol";
import "./AddressUpgradeable.sol";

/**
 * @notice A mixin that stores a reference to the Moments market contract.
 */
abstract contract MarketNode is Initializable {
    using AddressUpgradeable for address;

    address private market;

    /**
     * @dev Called once after the initial deployment to set the market address.
     */
    function _initializeMarketNode(address _market) internal initializer {
        require(_market.isContract(), "Market Node: Address is not a contract");
        market = _market;
    }

    /**
     * @notice Returns the address of the market.
     */
    function getMarket() public view returns (address) {
        return market;
    }

    /**
     * @notice Updates the address of the market.
     */
    function _updateMarket(address _market) internal {
        require(_market.isContract(), "Market Node: Address is not a contract");
        market = _market;
    }

    uint256[1000] private __gap;
}
