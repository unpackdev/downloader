// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

abstract contract Constants {
    /**
     * @notice minmum price for sale asset.
     */
    uint256 internal constant MIN_PRICE = 100;
    /**
     * @notice minimum, time for auction.
     */

    uint256 internal constant MIN_AUCTION_DURATION = 15 minutes;
    /**
     * @notice maximum time for auction.
     */
    uint256 internal constant MAX_AUCTION_DURATION = 7 days;
    /**
     * @notice minimum time for auction, if end time
     *   is less than extantion add extantion duraion to endTime.
     */
    uint256 internal constant EXTENSION_DURATION = 15 minutes;
}
