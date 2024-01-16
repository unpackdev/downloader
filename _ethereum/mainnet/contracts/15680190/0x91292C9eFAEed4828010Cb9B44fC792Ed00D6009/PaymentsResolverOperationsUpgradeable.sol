// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./AssetEnumsUpgradeable.sol";
import "./IProtocolSettings.sol";
import "./AccessControlUpgradeable.sol";
import "./RoleConstantsUpgradeable.sol";

/**
 * @title PaymentsResolverOperationsUpgradeable
 * @author NeatFi
 * @notice This contract holds the operations to resolve payments
 *         to Order makers in native tokens.
 */
contract PaymentsResolverOperationsUpgradeable is
    AssetEnumsUpgradeable,
    RoleConstantsUpgradeable,
    AccessControlUpgradeable
{
    address protocolSettings;

    /**
     * @dev An internal function to update the address of the
     *      current implementation of the NeatFi protocol settings contract.
     */
    function _updateProtocolSettingsAddress(address newProtocolSettings)
        internal
    {
        protocolSettings = newProtocolSettings;
    }

    /**
     * @dev An internal function to calculate Order maker earnings
     *      for an English Auction Order.
     * @param value - The settlement value of the Order.
     * @return makerEarnings - The earnings of the Order maker in
     *         native tokens.
     */
    function _englishAuctionFeeResolver(uint256 value)
        internal
        view
        returns (uint256 makerEarnings)
    {
        return
            value -
            ((value *
                IProtocolSettings(protocolSettings)
                    .getEnglishAuctionProtocolFeeNumerator()) / 1000);
    }

    /**
     * @dev An internal function to calculate Order maker earnings
     *      for a Dutch Auction Order.
     * @param value - The settlement value of the Order.
     * @return makerEarnings - The earnings of the Order maker in
     *         native tokens.
     */
    function _dutchAuctionFeeResolver(uint256 value)
        internal
        view
        returns (uint256 makerEarnings)
    {
        return
            value -
            ((value *
                IProtocolSettings(protocolSettings)
                    .getDutchAuctionProtocolFeeNumerator()) / 1000);
    }

    /**
     * @dev An internal function to calculate Order maker earnings
     *      for a Sell Order.
     * @param value - The settlement value of the Order.
     * @return makerEarnings - The earnings of the Order maker in
     *         native tokens.
     */
    function _sellFeeResolver(uint256 value)
        internal
        view
        returns (uint256 makerEarnings)
    {
        uint256 sellProtocolFeeNumerator = IProtocolSettings(protocolSettings)
            .getSellProtocolFeeNumerator();
        return value - ((value * sellProtocolFeeNumerator) / 1000);
    }

    /**
     * @dev An internal function to retrieve the protocol fee
     *      for a Swap Order creation.
     * @return feeToBePaid - The protocol fee for Swap Order creation.
     */
    function _swapFeeResolver() internal view returns (uint256 feeToBePaid) {
        return IProtocolSettings(protocolSettings).getSwapProtocolFee();
    }

    /** Initializers */

    function __PaymentsResolverOperations_init(address _protocolSettings)
        internal
        initializer
    {
        __AssetEnums_init();
        __RoleConstants_init();
        __AccessControl_init();

        _updateProtocolSettingsAddress(_protocolSettings);
    }
}
