// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./PaymentsResolverOperationsUpgradeable.sol";
import "./UUPSUpgradeable.sol";

/**
 * @title PaymentsResolverOperationsV1
 * @author NeatFi
 * @notice This contract implements the external facing functionality
 *         for the Payments Resolver contract of NeatFi.
 */
contract PaymentsResolverOperationsV1 is
    PaymentsResolverOperationsUpgradeable,
    UUPSUpgradeable
{
    string internal name;
    string internal currentVersion;

    /**
     * @dev Sets the version for the current implementation of this contract.
     */
    function _setVersion(string memory newVersion) internal {
        currentVersion = newVersion;
    }

    /**
     * @dev An external function to update the address of the
     *      current implementation of the NeatFi protocol settings contract.
     *      Can be executed by a Protocol Admin only.
     */
    function updateProtocolSettingsAddress(address newProtocolAddress)
        external
        onlyRole(PROTOCOL_ADMIN)
    {
        _updateProtocolSettingsAddress(newProtocolAddress);
    }

    /**
     * @dev An external function to calculate Order maker earnings
     *      for an English Auction Order. Can be called from the
     *      NeatFi contract only.
     * @param value - The settlement value of the Order.
     * @return makerEarnings - The earnings of the Order maker in
     *         native tokens.
     */
    function englishAuctionFeeResolver(uint256 value)
        external
        view
        onlyRole(AUTHORIZED_OPERATOR)
        returns (uint256 makerEarnings)
    {
        return _englishAuctionFeeResolver(value);
    }

    /**
     * @dev An external function to calculate Order maker earnings
     *      for a Dutch Auction Order. Can be called from the
     *      NeatFi contract only.
     * @param value - The settlement value of the Order.
     * @return makerEarnings - The earnings of the Order maker in
     *         native tokens.
     */
    function dutchAuctionFeeResolver(uint256 value)
        external
        view
        onlyRole(AUTHORIZED_OPERATOR)
        returns (uint256 makerEarnings)
    {
        return _dutchAuctionFeeResolver(value);
    }

    /**
     * @dev An external function to calculate Order maker earnings
     *      for a Sell Order. Can be called from the
     *      NeatFi contract only.
     * @param value - The settlement value of the Order.
     * @return makerEarnings - The earnings of the Order maker in
     *         native tokens.
     */
    function sellFeeResolver(uint256 value)
        external
        view
        onlyRole(AUTHORIZED_OPERATOR)
        returns (uint256 makerEarnings)
    {
        return _sellFeeResolver(value);
    }

    /**
     * @dev An external function to retrieve the protocol fee
     *      for a Swap Order creation. Can be called from the
     *      NeatFi contract only.
     * @return feeToBePaid - The protocol fee for Swap Order creation.
     */
    function swapFeeResolver()
        external
        view
        onlyRole(AUTHORIZED_OPERATOR)
        returns (uint256 feeToBePaid)
    {
        return _swapFeeResolver();
    }

    /** Initializers */

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(PROTOCOL_ADMIN)
    {}

    function initialize(address protocolSettings) public initializer {
        __UUPSUpgradeable_init();
        __PaymentsResolverOperations_init(protocolSettings);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        name = "NeatFi Payments Resolver";
        _setVersion("1.0.0");
    }
}
