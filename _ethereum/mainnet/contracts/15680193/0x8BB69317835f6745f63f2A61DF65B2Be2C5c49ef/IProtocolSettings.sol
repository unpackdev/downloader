// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @title IProtocolSettings
 * @author NeatFi
 * @notice Interface to the {ProtocolSettings} contract of NeatFi.
 */
interface IProtocolSettings {
    /**
     * @notice Retrieves the protocol fee for an English Auction Order resolution.
     * @dev Called only from the NeatFi contract.
     * @return englishAuctionFeeNumerator - The protocol fee value.
     */
    function getEnglishAuctionProtocolFeeNumerator()
        external
        view
        returns (uint256 englishAuctionFeeNumerator);

    /**
     * @notice Retrieves the protocol fee for a Dutch Auction Order resolution.
     * @dev Called only from the NeatFi contract.
     * @return dutchAuctionFeeNumerator - The protocol fee value.
     */
    function getDutchAuctionProtocolFeeNumerator()
        external
        view
        returns (uint256 dutchAuctionFeeNumerator);

    /**
     * @notice Retrieves the protocol fee for a Sell Order resolution.
     * @dev Called only from the NeatFi contract.
     */
    function getSellProtocolFeeNumerator()
        external
        view
        returns (uint256 sellProtocolFeeNumerator);

    /**
     * @notice Retrieves the protocol fee for a Swap Order creation.
     * @dev Called only from the NeatFi contract.
     */
    function getSwapProtocolFee()
        external
        view
        returns (uint256 swapProtocolFee);

    /**
     * @notice Retrieves the numerator for Actor earnings.
     * @dev Called only from the NeatFi contract.
     */
    function getActorEarningsNumerator()
        external
        view
        returns (uint256 actorEarningsNumerator);

    /**
     * @notice Retrieves the numerator for protocol fee distribution.
     * @dev Called only from the NeatFi contract.
     */
    function getProtocolFeeDistributionNumerator()
        external
        view
        returns (uint256 protocolFeeDistributionNumerator);
}
