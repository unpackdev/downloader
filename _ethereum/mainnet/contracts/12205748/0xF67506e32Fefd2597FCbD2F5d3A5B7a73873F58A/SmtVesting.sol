//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

contract SmtVesting is Ownable {
    using SafeMath for uint256;

    /// @dev ERC20 basic token contract being held
    IERC20 public token;

    /// @dev Block number where the contract is deployed
    uint256 public immutable initialBlock;

    uint256 private constant ONE = 10**18;
    uint256 private constant DAY = 5760; // 24*60*60/15
    uint256 private constant WEEK = 40320; // 7*24*60*60/15
    uint256 private constant YEAR = 2102400; // 365*24*60*60/15
    uint256 private constant WEEKS_IN_YEAR = 52;
    uint256 private constant INITAL_ANUAL_DIST = 62500000 * ONE;
    uint256 private constant WEEK_BATCH_DIV = 45890222137623526749; //(0.995^0 + 0.995^1 ... + 0.995^51) = 45,894396603

    /// @dev First year comunity batch has been claimed
    bool public firstYCBClaimed;

    /// @dev Block number where last claim was executed
    uint256 public lastClaimedBlock;

    /// @dev Emitted when `owner` claims.
    event Claim(address indexed owner, uint256 amount);

    /**
     * @dev Sets the value for {initialBloc}.
     *
     * Sets ownership to the given `_owner`.
     *
     */
    constructor() {
        initialBlock = block.number;
        lastClaimedBlock = block.number;
    }

    /**
     * @dev Sets the value for `token`.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_token` can't be zero address
     * - `token` should not be already set
     *
     */
    function setToken(address _token) external onlyOwner {
        require(_token != address(0), "token is the zero address");
        require(address(token) == address(0), "token is already set");
        token = IERC20(_token);
    }

    /**
     * @dev Claims next token batch.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     *
     */
    function claim() external onlyOwner {
        uint256 amount = claimableAmount();
        lastClaimedBlock = block.number;
        firstYCBClaimed = true;
        emit Claim(owner(), amount);
        token.transfer(_msgSender(), amount);
    }

    /**
     * @dev Gets the next token batch to be claimed since the last claim until current block.
     *
     */
    function claimableAmount() public view returns (uint256) {
        return _claimableAmount(firstYCBClaimed, block.number, lastClaimedBlock);
    }

    /**
     * @dev Gets the next token batch to be claimed since the last claim until current block.
     *
     */
    function _claimableAmount(
        bool isFirstYCBClaimed,
        uint256 blockNumber,
        uint256 lCBlock
    ) internal view returns (uint256) {
        uint256 total = 0;
        uint256 lastClaimedBlockYear = blockYear(lCBlock);
        uint256 currentYear = blockYear(blockNumber);

        total += accumulateAnualComBatch(isFirstYCBClaimed, blockNumber, lCBlock);

        if (lastClaimedBlockYear < currentYear) {
            total += accumulateFromPastYears(blockNumber, lCBlock);
        } else {
            total += accumulateCurrentYear(blockNumber, lCBlock);
        }

        return total;
    }

    /**
     * @dev Accumulates non claimed Anual Comunity Batches.
     *
     */
    function accumulateAnualComBatch(
        bool isFirstYCBClaimed,
        uint256 blockNumber,
        uint256 lCBlock
    ) public view returns (uint256) {
        uint256 acc = 0;
        uint256 currentYear = blockYear(blockNumber);
        uint256 lastClaimedBlockYear = blockYear(lCBlock);
        if (!isFirstYCBClaimed || lastClaimedBlockYear < currentYear) {
            uint256 from = isFirstYCBClaimed ? lastClaimedBlockYear + 1 : 0;
            for (uint256 y = from; y <= currentYear; y++) {
                acc += yearAnualCommunityBatch(y);
            }
        }

        return acc;
    }

    /**
     * @dev Accumulates non claimed Weekly Release Batches from a week in a previous year.
     *
     */
    function accumulateFromPastYears(uint256 blockNumber, uint256 lCBlock) public view returns (uint256) {
        uint256 acc = 0;
        uint256 lastClaimedBlockYear = blockYear(lCBlock);
        uint256 lastClaimedBlockWeek = blockWeek(lCBlock);
        uint256 currentYear = blockYear(blockNumber);
        uint256 currentWeek = blockWeek(blockNumber);

        // add what remains to claim from the claimed week
        acc += getWeekPortionFromBlock(lCBlock);

        {
            uint256 ww;
            uint256 yy;
            for (ww = lastClaimedBlockWeek + 1; ww < WEEKS_IN_YEAR; ww++) {
                acc += yearWeekRelaseBatch(lastClaimedBlockYear, ww);
            }

            // add complete weeks years until current year
            for (yy = lastClaimedBlockYear + 1; yy < currentYear; yy++) {
                for (ww = 0; ww < WEEKS_IN_YEAR; ww++) {
                    acc += yearWeekRelaseBatch(yy, ww);
                }
            }

            // current year until current week
            for (ww = 0; ww < currentWeek; ww++) {
                acc += yearWeekRelaseBatch(currentYear, ww);
            }
        }

        // portion of current week
        acc += getWeekPortionUntilBlock(blockNumber);

        return acc;
    }

    /**
     * @dev Accumulates non claimed Weekly Release Batches from a week in the current year.
     *
     */
    function accumulateCurrentYear(uint256 blockNumber, uint256 lCBlock) public view returns (uint256) {
        uint256 acc = 0;
        uint256 lastClaimedBlockWeek = blockWeek(lCBlock);
        uint256 currentYear = blockYear(blockNumber);
        uint256 currentWeek = blockWeek(blockNumber);

        if (lastClaimedBlockWeek < currentWeek) {
            // add what remains to claim from the claimed week
            acc += getWeekPortionFromBlock(lCBlock);

            {
                uint256 ww;
                // add remaining weeks until current
                for (ww = lastClaimedBlockWeek + 1; ww < currentWeek; ww++) {
                    acc += yearWeekRelaseBatch(currentYear, ww);
                }
            }
        }

        // portion of current week
        acc += getWeekPortionUntilBlock(blockNumber);

        return acc;
    }

    // Utility Functions

    /**
     * @dev Calculates the portion of Weekly Release Batch from a block to the end of that block's week.
     *
     */
    function getWeekPortionFromBlock(uint256 blockNumber) internal view returns (uint256) {
        uint256 blockNumberYear = blockYear(blockNumber);
        uint256 blockNumberWeek = blockWeek(blockNumber);

        uint256 blockNumberWeekBatch = yearWeekRelaseBatch(blockNumberYear, blockNumberWeek);
        uint256 weekLastBlock = yearWeekLastBlock(blockNumberYear, blockNumberWeek);
        return blockNumberWeekBatch.mul(weekLastBlock.sub(blockNumber)).div(WEEK);
    }

    /**
     * @dev Calculates the portion of Weekly Release Batch from the start of a block's week the block.
     *
     */
    function getWeekPortionUntilBlock(uint256 blockNumber) internal view returns (uint256) {
        uint256 blockNumberYear = blockYear(blockNumber);
        uint256 blockNumberWeek = blockWeek(blockNumber);

        uint256 blockNumberWeekBatch = yearWeekRelaseBatch(blockNumberYear, blockNumberWeek);
        uint256 weekFirsBlock = yearWeekFirstBlock(blockNumberYear, blockNumberWeek);
        return blockNumberWeekBatch.mul(blockNumber.sub(weekFirsBlock)).div(WEEK);
    }

    /**
     * @dev Calculates the Total Anual Distribution for a given year.
     *
     * TAD = (62500000) * (1 - 0.25)^y
     *
     * @param year Year zero based.
     */
    function yearAnualDistribution(uint256 year) public pure returns (uint256) {
        // 25% of year reduction => (1-0.25) = 0.75 = 3/4
        uint256 reductionN = 3**year;
        uint256 reductionD = 4**year;
        return INITAL_ANUAL_DIST.mul(reductionN).div(reductionD);
    }

    /**
     * @dev Calculates the Anual Comunity Batch for a given year.
     *
     * 20% * yearAnualDistribution
     *
     * @param year Year zero based.
     */
    function yearAnualCommunityBatch(uint256 year) public pure returns (uint256) {
        uint256 totalAnnualDistribution = yearAnualDistribution(year);
        return totalAnnualDistribution.mul(200).div(1000);
    }

    /**
     * @dev Calculates the Anual Weekly Batch for a given year.
     *
     * 80% * yearAnualDistribution
     *
     * @param year Year zero based.
     */
    function yearAnualWeeklyBatch(uint256 year) public pure returns (uint256) {
        uint256 yearAC = yearAnualCommunityBatch(year);
        return yearAnualDistribution(year).sub(yearAC);
    }

    /**
     * @dev Calculates weekly reduction percentage for a given week.
     *
     * WRP = (1 - 0.5)^w
     *
     * @param week Week zero based.
     */
    function weeklyRedPerc(uint256 week) internal pure returns (uint256) {
        uint256 reductionPerc = ONE;
        uint256 nineNineFive = ONE - 5000000000000000; // 1 - 0.5
        for (uint256 i = 0; i < week; i++) {
            reductionPerc = nineNineFive.mul(reductionPerc).div(ONE);
        }

        return reductionPerc;
    }

    /**
     * @dev Calculates W1 weekly release batch amount for a given year.
     *
     * yearAnualWeeklyBatch / (0.995^0 + 0.995^1 ... + 0.995^51)
     *
     * @param year Year zero based.
     */
    function yearFrontWeightedWRB(uint256 year) internal pure returns (uint256) {
        uint256 totalWeeklyAnualBatch = yearAnualWeeklyBatch(year);

        return totalWeeklyAnualBatch.mul(ONE).div(WEEK_BATCH_DIV);
    }

    /**
     * @dev Calculates the Weekly Release Batch amount for the given year and week.
     *
     * @param year Year zero based.
     * @param week Week zero based.
     */
    function yearWeekRelaseBatch(uint256 year, uint256 week) public pure returns (uint256) {
        uint256 yearW1 = yearFrontWeightedWRB(year);
        uint256 weeklyRedPercentage = weeklyRedPerc(week);

        return yearW1.mul(weeklyRedPercentage).div(ONE);
    }

    /**
     * @dev Gets first block of the given year.
     *
     * @param year Year zero based.
     */
    function yearFirstBlock(uint256 year) internal view returns (uint256) {
        return initialBlock.add(YEAR.mul(year));
    }

    /**
     * @dev Gets first block of the given year and week.
     *
     * @param year Year zero based.
     * @param week Week zero based.
     */
    function yearWeekFirstBlock(uint256 year, uint256 week) internal view returns (uint256) {
        uint256 yFB = yearFirstBlock(year);
        return yFB.add(WEEK.mul(week));
    }

    /**
     * @dev Gets last block of the given year and week.
     *
     * @param year Year zero based.
     * @param week Week zero based.
     */
    function yearWeekLastBlock(uint256 year, uint256 week) internal view returns (uint256) {
        return yearWeekFirstBlock(year, week + 1);
    }

    /**
     * @dev Gets the year of a given block.
     *
     * @param blockNumber Block number.
     */
    function blockYear(uint256 blockNumber) internal view returns (uint256) {
        return (blockNumber.sub(initialBlock)).div(YEAR);
    }

    /**
     * @dev Gets the week of a given block within the block year.
     *
     * @param blockNumber Block number.
     */
    function blockWeek(uint256 blockNumber) internal view returns (uint256) {
        return (blockNumber.sub(yearFirstBlock(blockYear(blockNumber)))).div(WEEK);
    }
}
