// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./IERC20Permit.sol";
import "./Errors.sol";
import "./DataTypes.sol";
import "./AdminPausableUpgradeSafe.sol";

/**
 * @title AdminPausableAuctionBaseUpgradeSafe
 *
 * @author Aito
 *
 * @dev A simple implementation that holds basic auction parameter functionality, common to both Aave staking and
 * generic auction types.
 */
abstract contract AuctionBase is AdminPausableUpgradeSafe {
    using SafeERC20 for IERC20Permit;
    using SafeMath for uint256;

    uint16 public constant BPS_MAX = 10000;

    address internal _treasury;
    uint40 internal _minimumAuctionDuration;
    uint40 internal _overtimeWindow;
    uint16 internal _treasuryFeeBps;
    uint8 internal _distributionCap;

    event TreasuryFeeChanged(uint16 newTreasuryFeeBps);
    event TreasuryAddressChanged(address newTreasury);
    event MinimumAuctionDurationChanged(uint40 newMinimumDuration);
    event OvertimeWindowChanged(uint40 newOvertimeWindow);
    event DistributionCapChanged(uint8 newDistributionCap);

    /**
     * @dev Admin function to change the treasury fee BPS.
     *
     * @param newTreasuryFeeBps The new treasury fee to use.
     */
    function setTreasuryFeeBps(uint16 newTreasuryFeeBps) external onlyAdmin {
        require(newTreasuryFeeBps < BPS_MAX, Errors.INVALID_INIT_PARAMS);
        _treasuryFeeBps = newTreasuryFeeBps;
        emit TreasuryFeeChanged(newTreasuryFeeBps);
    }

    /**
     * @dev Admin function to change the treasury address.
     *
     * @param newTreasury The new treasury address to use.
     */
    function setTreasuryAddress(address newTreasury) external onlyAdmin {
        require(newTreasury != address(0), Errors.INVALID_INIT_PARAMS);
        _treasury = newTreasury;
        emit TreasuryAddressChanged(newTreasury);
    }

    /**
     * @dev Admin function to change the minimum auction duration.
     *
     * @param newMinimumDuration The new minimum auction duration to set.
     */
    function setMinimumAuctionDuration(uint40 newMinimumDuration) external onlyAdmin {
        require(newMinimumDuration > _overtimeWindow, Errors.INVALID_INIT_PARAMS);
        _minimumAuctionDuration = newMinimumDuration;
        emit MinimumAuctionDurationChanged(newMinimumDuration);
    }

    /**
     * @dev Admin function to set the auction overtime window.
     *
     * @param newOvertimeWindow The new overtime window to set.
     */
    function setOvertimeWindow(uint40 newOvertimeWindow) external onlyAdmin {
        require(
            newOvertimeWindow < _minimumAuctionDuration && newOvertimeWindow < 2 days,
            Errors.INVALID_INIT_PARAMS
        );
        _overtimeWindow = newOvertimeWindow;
        emit OvertimeWindowChanged(newOvertimeWindow);
    }

    /**
     * @dev Admin function to change the distribution cap.
     *
     * @param newDistributionCap The new distribution cap to set.
     */
    function setDistributionCap(uint8 newDistributionCap) external onlyAdmin {
        require(newDistributionCap > 0, Errors.INVALID_INIT_PARAMS);
        _distributionCap = newDistributionCap;
        emit DistributionCapChanged(newDistributionCap);
    }

    /**
     * @notice Bids on a given NFT with a given amount.
     *
     * @param onBehalfOf The address to bid on behalf of.
     * @param nft The NFT address to bid on.
     * @param nftId The NFT ID to bid on.
     * @param amount The amount to bid with.
     */
    function bid(
        address onBehalfOf,
        address nft,
        uint256 nftId,
        uint256 amount
    ) external virtual whenNotPaused {
        _bid(msg.sender, onBehalfOf, nft, nftId, amount);
    }

    /**
     * @dev Internal function that distributes a given ERC20 token and token amount according to a given
     * distribution array.
     *
     * @param currency The currency address to distribute.
     * @param amount The total amount to distribute.
     * @param distribution The distribution array.
     */
    function _distribute(
        address currency,
        uint256 amount,
        DataTypes.DistributionData[] memory distribution
    ) internal {
        require(distribution.length > 0, Errors.INVALID_DISTRIBUTION_COUNT);
        IERC20Permit token = IERC20Permit(currency);
        uint256 leftover = amount;
        uint256 distributionAmount;
        for (uint256 i = 0; i < distribution.length; i++) {
            distributionAmount = amount.mul(distribution[i].bps).div(BPS_MAX);
            leftover = leftover.sub(distributionAmount);
            token.safeTransfer(distribution[i].recipient, distributionAmount);
        }

        // Treasury gets the leftovers, equal to amount.mul(_treasuryFeeBps).div(BPS_MAX) for rounding errors.
        if (leftover > 0) {
            token.safeTransfer(_treasury, leftover);
        }
    }

    function _bid(
        address spender,
        address onBehalfOf,
        address nft,
        uint256 nftId,
        uint256 amount
    ) internal virtual;
}
