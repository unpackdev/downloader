// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./AccessControlUpgradeable.sol";
import "./RoleConstantsUpgradeable.sol";
import "./LimitsVerifier.sol";
import "./UUPSUpgradeable.sol";

/**
 * @title ProtocolSettingsV1
 * @author NeatFi
 * @notice This contract implements the external facing functionality
 *         for the Protocol Settings contract of NeatFi.
 */
contract ProtocolSettingsV1 is
    UUPSUpgradeable,
    RoleConstantsUpgradeable,
    AccessControlUpgradeable,
    LimitsVerifier
{
    string internal name;
    string internal currentVersion;

    // Protocol fee numerator for ENGLISH_AUCTION.
    uint256 public englishAuctionProtocolFeeNumerator;

    // Protocol fee numerator for DUTCH_AUCTION.
    uint256 public dutchAuctionProtocolFeeNumerator;

    // Protocol fee numerator for SELL.
    uint256 public sellProtocolFeeNumerator;

    // Protocol fee for SWAP creation.
    uint256 public swapProtocolFee;

    /**
     * @notice Numerator to calculate earnings from protocol fees for Actor contracts.
     *         Value between 0 and 1000.
     */
    uint256 public actorEarningsNumerator;

    /**
     * @notice Numerator to calculate the percentage of the protocol fee to be
     *         distributed to Neat holders who have locked their Neats on the
     *         treasury contract. Value between 0 and 1000.
     */
    uint256 public protocolFeeDistributionNumerator;

    /**
     * @dev An internal function to set new protocolFeeDistributionNumerator.
     * @param newProtocolFeeDistributionNumerator - new protocolFeeDistributionNumerator.
     */
    function _setProtocolFeeDistributionNumerator(
        uint256 newProtocolFeeDistributionNumerator
    ) internal {
        protocolFeeDistributionNumerator = newProtocolFeeDistributionNumerator;
    }

    /**
     * @dev An internal function to set new actorEarningsNumerator.
     * @param newActorEarningsNumerator - new actorEarningsNumerator.
     */
    function _setActorEarningsNumerator(uint256 newActorEarningsNumerator)
        internal
    {
        actorEarningsNumerator = newActorEarningsNumerator;
    }

    /**
     * @dev An internal function to set a new englishAuctionFeeNumerator.
     * @param newEnglishAuctionProtocolFeeNumerator - new englishAuctionFeeNumerator.
     */
    function _setEnglishAuctionProtocolFeeNumerator(
        uint256 newEnglishAuctionProtocolFeeNumerator
    ) internal {
        englishAuctionProtocolFeeNumerator = newEnglishAuctionProtocolFeeNumerator;
    }

    /**
     * @dev An internal function to set a new dutchAuctionProtocolFeeNumerator.
     * @param newDutchAuctionProtocolFeeNumerator - new dutchAuctionFeeNumerator.
     */
    function _setDutchAuctionProtocolFeeNumerator(
        uint256 newDutchAuctionProtocolFeeNumerator
    ) internal {
        dutchAuctionProtocolFeeNumerator = newDutchAuctionProtocolFeeNumerator;
    }

    /**
     * @dev An internal function to set a new swapProtocolFee.
     * @param newSwapProtocolFee - new simpleSwapProtocolFee.
     */
    function _setSwapProtocolFee(uint256 newSwapProtocolFee)
        internal
        isWithinLimits(newSwapProtocolFee)
    {
        swapProtocolFee = newSwapProtocolFee;
    }

    /**
     * @dev An internal function to set a new sellProtocolFee.
     * @param newSellProtocolFeeNumerator - new simpleSellProtocolFee.
     */
    function _setSellProtocolFeeNumerator(uint256 newSellProtocolFeeNumerator)
        internal
    {
        sellProtocolFeeNumerator = newSellProtocolFeeNumerator;
    }

    function getEnglishAuctionProtocolFeeNumerator()
        external
        view
        returns (uint256 englishAuctionFeeNumerator)
    {
        return englishAuctionProtocolFeeNumerator;
    }

    /**
     * @dev An internal function to get the protocol fee numerator
     *      for Dutch auction.
     */
    function getDutchAuctionProtocolFeeNumerator()
        external
        view
        returns (uint256 dutchAuctionFeeNumerator)
    {
        return dutchAuctionProtocolFeeNumerator;
    }

    /**
     * @dev An internal function to get the protocol fee numerator
     *      for Sell order.
     */
    function getSellProtocolFeeNumerator() external view returns (uint256) {
        return sellProtocolFeeNumerator;
    }

    /**
     * @dev An internal function to get the protocol fee
     *      for Swap order.
     */
    function getSwapProtocolFee() external view returns (uint256) {
        return swapProtocolFee;
    }

    /**
     * @dev An internal function to get the numerator
     *      for Actor earnings.
     */
    function getActorEarningsNumerator() external view returns (uint256) {
        return actorEarningsNumerator;
    }

    /**
     * @dev An internal function to get the numerator
     *      for the protocol fee distribution.
     */
    function getProtocolFeeDistributionNumerator()
        external
        view
        returns (uint256)
    {
        return protocolFeeDistributionNumerator;
    }

    /**
     * @dev Sets the version for the current implementation of this contract.
     */
    function _setVersion(string memory newVersion) internal {
        currentVersion = newVersion;
    }

    /**
     * @dev An external function to set a new newEnglishAuctionProtocolFeeNumerator.
     * @param newEnglishAuctionProtocolFeeNumerator - new englishAuctionFeeNumerator.
     */
    function setEnglishAuctionProtocolFeeNumerator(
        uint256 newEnglishAuctionProtocolFeeNumerator
    ) external onlyRole(PROTOCOL_ADMIN) {
        _setEnglishAuctionProtocolFeeNumerator(
            newEnglishAuctionProtocolFeeNumerator
        );
    }

    /**
     * @dev An external function to set a new newDutchAuctionProtocolFeeNumerator.
     * @param newDutchAuctionProtocolFeeNumerator - new dutchAuctionFeeNumerator.
     */
    function setDutchAuctionProtocolFeeNumerator(
        uint256 newDutchAuctionProtocolFeeNumerator
    ) external onlyRole(PROTOCOL_ADMIN) {
        _setDutchAuctionProtocolFeeNumerator(
            newDutchAuctionProtocolFeeNumerator
        );
    }

    /**
     * @dev An external function to set a new setSwapProtocolFee.
     * @param newSwapProtocolFee - new newSwapProtocolFee.
     */
    function setSwapProtocolFee(uint256 newSwapProtocolFee)
        external
        onlyRole(PROTOCOL_ADMIN)
        isWithinLimits(newSwapProtocolFee)
    {
        _setSwapProtocolFee(newSwapProtocolFee);
    }

    /**
     * @dev An external function to set a new setSellProtocolFee.
     * @param newSellProtocolFeeNumerator - new newSellProtocolFeeNumerator.
     */
    function setSellProtocolFeeNumerator(uint256 newSellProtocolFeeNumerator)
        external
        onlyRole(PROTOCOL_ADMIN)
    {
        _setSellProtocolFeeNumerator(newSellProtocolFeeNumerator);
    }

    /** Initializers */

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(PROTOCOL_ADMIN)
    {}

    function initialize(
        uint256 newProtocolFeeDistributionNumerator,
        uint256 newSwapProtocolFeeValue,
        uint256 newSellProtocolFeeNumeratorValue,
        uint256 newDutchAuctionProtocolFeeNumeratorValue,
        uint256 newEnglishAuctionProtocolFeeNumeratorValue,
        uint256 newActorEarningsNumerator
    ) public initializer onlyProxy {
        __UUPSUpgradeable_init();
        __RoleConstants_init();
        __AccessControl_init();

        _setProtocolFeeDistributionNumerator(
            newProtocolFeeDistributionNumerator
        );
        _setSwapProtocolFee(newSwapProtocolFeeValue);
        _setSellProtocolFeeNumerator(newSellProtocolFeeNumeratorValue);
        _setEnglishAuctionProtocolFeeNumerator(
            newDutchAuctionProtocolFeeNumeratorValue
        );
        _setDutchAuctionProtocolFeeNumerator(
            newEnglishAuctionProtocolFeeNumeratorValue
        );
        _setActorEarningsNumerator(newActorEarningsNumerator);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        name = "NeatFi Payments Transfer Resolver";
        _setVersion("1.0.0");
    }
}
