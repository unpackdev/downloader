// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Governed.sol";
import "./OwnerBalanceContributor.sol";
import "./Macabris.sol";
import "./Reaper.sol";

/**
 * @title Contract tracking payouts to token owners according to predefined schedule
 *
 * Payout schedule is dived into intervalCount intervals of intervalLength durations, starting at
 * startTime timestamp. After each interval, part of the payouts pool is distributed to the owners
 * of the tokens that are still alive. After the whole payout schedule is completed, all the funds
 * in the payout pool will have been distributed.
 *
 * There is a possibility of the payout schedule being stopped early. In that case, all of the
 * remaining funds will be distributed to the owners of the tokens that were alive at the time of
 * the payout schedule stop.
 */
contract Bank is Governed, OwnerBalanceContributor {

    // Macabris NFT contract
    Macabris public macabris;

    // Reaper contract
    Reaper public reaper;

    // Stores active token count change and deposits for an interval
    struct IntervalActivity {
        int128 activeTokenChange;
        uint128 deposits;
    }

    // Stores aggregate interval information
    struct IntervalTotals {
        uint index;
        uint deposits;
        uint payouts;
        uint accountPayouts;
        uint activeTokens;
        uint accountActiveTokens;
    }

    // The same as IntervalTotals, but a packed version to keep in the lastWithdrawTotals map.
    // Packed versions costs less to store, but the math is then more expensive duo to type
    // conversions, so the interval data is packed just before storing, and unpacked after loading.
    struct IntervalTotalsPacked {
        uint128 deposits;
        uint128 payouts;
        uint128 accountPayouts;
        uint48 activeTokens;
        uint48 accountActiveTokens;
        uint32 index;
    }

    // Timestamp of when the first interval starts
    uint64 public immutable startTime;

    // Timestamp of the moment the payouts have been stopped and the bank contents distributed.
    // This should remain 0, if the payout schedule is never stopped manually.
    uint64 public stopTime;

    // Total number of intervals
    uint64 public immutable intervalCount;

    // Interval length in seconds
    uint64 public immutable intervalLength;

    // Activity for each interval
    mapping(uint => IntervalActivity) private intervals;

    // Active token change for every interval for every address individually
    mapping(uint => mapping(address => int)) private individualIntervals;

    // Total withdrawn amount fo each address
    mapping(address => uint) private withdrawals;

    // Totals of the interval before the last withdrawal of an address
    mapping(address => IntervalTotalsPacked) private lastWithdrawTotals;

    /**
     * @param _startTime First interval start unix timestamp
     * @param _intervalCount Interval count
     * @param _intervalLength Interval length in seconds
     * @param governanceAddress Address of the Governance contract
     * @param ownerBalanceAddress Address of the OwnerBalance contract
     *
     * Requirements:
     * - interval length must be at least one second (but should be more like a month)
     * - interval count must be bigger than zero
     * - Governance contract must be deployed at the given address
     * - OwnerBalance contract must be deployed at the given address
     */
    constructor(
        uint64 _startTime,
        uint64 _intervalCount,
        uint64 _intervalLength,
        address governanceAddress,
        address ownerBalanceAddress
    ) Governed(governanceAddress) OwnerBalanceContributor(ownerBalanceAddress) {
        require(_intervalLength > 0, "Interval length can't be zero");
        require(_intervalCount > 0, "At least one interval is required");

        startTime = _startTime;
        intervalCount = _intervalCount;
        intervalLength = _intervalLength;
    }

    /**
     * @dev Sets Macabris NFT contract address
     * @param macabrisAddress Address of Macabris NFT contract
     *
     * Requirements:
     * - the caller must have the bootstrap permission
     * - Macabris contract must be deployed at the given address
     */
    function setMacabrisAddress(address macabrisAddress) external canBootstrap(msg.sender) {
        macabris = Macabris(macabrisAddress);
    }

    /**
     * @dev Sets Reaper contract address
     * @param reaperAddress Address of Reaper contract
     *
     * Requirements:
     * - the caller must have the bootstrap permission
     * - Reaper contract must be deployed at the given address
     */
    function setReaperAddress(address reaperAddress) external canBootstrap(msg.sender) {
        reaper = Reaper(reaperAddress);
    }

    /**
     * @dev Stops payouts, distributes remaining funds among alive tokens
     *
     * Requirements:
     * - the caller must have the stop payments permission
     * - the payout schedule must not have been stopped previously
     * - the payout schedule should not be completed
     */
    function stopPayouts() external canStopPayouts(msg.sender) {
        require(stopTime == 0, "Payouts are already stopped");
        require(block.timestamp < getEndTime(), "Payout schedule is already completed");
        stopTime = uint64(block.timestamp);
    }

    /**
     * @dev Checks if the payouts are finished or have been stopped manually
     * @return True if finished or stopped
     */
    function hasEnded() public view returns (bool) {
        return stopTime > 0 || block.timestamp >= getEndTime();
    }

    /**
     * @dev Returns timestamp of the first second after the last interval
     * @return Unix timestamp
     */
    function getEndTime() public view returns(uint) {
        return _getIntervalStartTime(intervalCount);
    }

    /**
     * @dev Returns a timestamp of the first second of the given interval
     * @return Unix timestamp
     *
     * Doesn't make any bound checks for the given interval!
     */
    function _getIntervalStartTime(uint interval) private view returns(uint) {
        return startTime + interval * intervalLength;
    }

    /**
     * @dev Returns start time of the upcoming interval
     * @return Unix timestamp
     */
    function getNextIntervalStartTime() public view returns (uint) {

        // If the payouts were ended manually, there will be no next interval
        if (stopTime > 0) {
            return 0;
        }

        // Returns first intervals start time if the payout schedule hasn't started yet
        if (block.timestamp < startTime) {
            return startTime;
        }

        uint currentInterval = _getInterval(block.timestamp);

        // There will be no intervals after the last one, return 0
        if (currentInterval >= (intervalCount - 1)) {
            return 0;
        }

        // Returns next interval's start time otherwise
        return _getIntervalStartTime(currentInterval + 1);
    }

    /**
     * @dev Deposits ether to the common payout pool
     */
    function deposit() external payable {

        // If the payouts have ended, we don't need to track deposits anymore, everything goes to
        // the owner's balance
        if (hasEnded()) {
            _transferToOwnerBalance(msg.value);
            return;
        }

        require(msg.value <= type(uint128).max, "Deposits bigger than uint128 max value are not allowed!");
        uint currentInterval = _getInterval(block.timestamp);
        intervals[currentInterval].deposits += uint128(msg.value);
    }

    /**
     * @dev Registers token transfer, minting and burning
     * @param tokenId Token ID
     * @param from Previous token owner, zero if this is a freshly minted token
     * @param to New token owner, zero if the token is being burned
     *
     * Requirements:
     * - the caller must be the Macabris contract
     */
    function onTokenTransfer(uint tokenId, address from, address to) external {
        require(msg.sender == address(macabris), "Caller must be the Macabris contract");

        // If the payouts have ended, we don't need to track transfers anymore
        if (hasEnded()) {
            return;
        }

        // If token is already dead, nothing changes in terms of payouts
        if (reaper.getTimeOfDeath(tokenId) != 0) {
            return;
        }

        uint currentInterval = _getInterval(block.timestamp);

        if (from == address(0)) {
            // If the token is freshly minted, increase the total active token count for the period
            intervals[currentInterval].activeTokenChange += 1;
        } else {
            // If the token is transfered, decrease the previous ownner's total for the current interval
            individualIntervals[currentInterval][from] -= 1;
        }

        if (to == address(0)) {
            // If the token is burned, decrease the total active token count for the period
            intervals[currentInterval].activeTokenChange -= 1;
        } else {
            // If the token is transfered, add it to the receiver's total for the current interval
            individualIntervals[currentInterval][to] += 1;
        }
    }

    /**
     * @dev Registers token death
     * @param tokenId Token ID
     *
     * Requirements:
     * - the caller must be the Reaper contract
     */
    function onTokenDeath(uint tokenId) external {
        require(msg.sender == address(reaper), "Caller must be the Reaper contract");

        // If the payouts have ended, we don't need to track deaths anymore
        if (hasEnded()) {
            return;
        }

        // If the token isn't minted yet, we don't care about it
        if (!macabris.exists(tokenId)) {
            return;
        }

        uint currentInterval = _getInterval(block.timestamp);
        address owner = macabris.ownerOf(tokenId);

        intervals[currentInterval].activeTokenChange -= 1;
        individualIntervals[currentInterval][owner] -= 1;
    }

    /**
     * @dev Registers token resurrection
     * @param tokenId Token ID
     *
     * Requirements:
     * - the caller must be the Reaper contract
     */
    function onTokenResurrection(uint tokenId) external {
        require(msg.sender == address(reaper), "Caller must be the Reaper contract");

        // If the payouts have ended, we don't need to track deaths anymore
        if (hasEnded()) {
            return;
        }

        // If the token isn't minted yet, we don't care about it
        if (!macabris.exists(tokenId)) {
            return;
        }

        uint currentInterval = _getInterval(block.timestamp);
        address owner = macabris.ownerOf(tokenId);

        intervals[currentInterval].activeTokenChange += 1;
        individualIntervals[currentInterval][owner] += 1;
    }

    /**
     * Returns current interval index
     * @return Interval index (0 for the first interval, intervalCount-1 for the last)
     *
     * Notes:
     * - Returns zero (first interval), if the first interval hasn't started yet
     * - Returns the interval at the stop time, if the payouts have been stopped
     * - Returns "virtual" interval after the last one, if the payout schedule is completed
     */
    function _getCurrentInterval() private view returns(uint) {

        // If the payouts have been stopped, return interval after the stopped one
        if (stopTime > 0) {
            return _getInterval(stopTime);
        }

        uint intervalIndex = _getInterval(block.timestamp);

        // Return "virtual" interval that would come after the last one, if payout schedule is completed
        if (intervalIndex > intervalCount) {
            return intervalCount;
        }

        return intervalIndex;
    }

    /**
     * Returns interval index for the given timestamp
     * @return Interval index (0 for the first interval, intervalCount-1 for the last)
     *
     * Notes:
     * - Returns zero (first interval), if the first interval hasn't started yet
     * - Returns non-exitent interval index, if the timestamp is after the end time
     */
    function _getInterval(uint timestamp) private view returns(uint) {

        // Time before the payout schedule start is considered to be a part of the first interval
        if (timestamp < startTime) {
            return 0;
        }

        return (timestamp - startTime) / intervalLength;
    }

    /**
     * @dev Returns total pool value (deposits - payouts) for the current interval
     * @return Current pool value in wei
     */
    function getPoolValue() public view returns (uint) {

        // If all the payouts are done, pool is empty. In reality, there might something left due to
        // last interval pool not dividing equaly between the remaining alive tokens, or if there
        // are no alive tokens during the last interval.
        if (hasEnded()) {
            return 0;
        }

        uint currentInterval = _getInterval(block.timestamp);
        IntervalTotals memory totals = _getIntervalTotals(currentInterval, address(0));

        return totals.deposits - totals.payouts;
    }

    /**
     * @dev Returns provisional next payout value per active token of the current interval
     * @return Payout in wei, zero if no active tokens exist or all payouts are done
     */
    function getNextPayout() external view returns (uint) {

        // There is no next payout if the payout schedule has run its course
        if (hasEnded()) {
            return 0;
        }

        uint currentInterval = _getInterval(block.timestamp);
        IntervalTotals memory totals = _getIntervalTotals(currentInterval, address(0));

        return _getPayoutPerToken(totals);
    }

    /**
     * @dev Returns payout amount per token for the given interval
     * @param totals Interval totals
     * @return Payout value in wei
     *
     * Notes:
     * - Returns zero for the "virtual" interval after the payout schedule end
     * - Returns zero if no active tokens exists for the interval
     */
    function _getPayoutPerToken(IntervalTotals memory totals) private view returns (uint) {
        // If we're calculating next payout for the "virtual" interval after the last one,
        // or if there are no active tokens, we would be dividing the pool by zero
        if (totals.activeTokens > 0 && totals.index < intervalCount) {
            return (totals.deposits - totals.payouts) / (intervalCount - totals.index) / totals.activeTokens;
        } else {
            return 0;
        }
    }

    /**
     * @dev Returns the sum of all payouts made up until this interval
     * @return Payouts total in wei
     */
    function getPayoutsTotal() external view returns (uint) {
        uint interval = _getCurrentInterval();
        IntervalTotals memory totals = _getIntervalTotals(interval, address(0));
        uint payouts = totals.payouts;

        // If the payout schedule has been stopped prematurely, all deposits are distributed.
        // If there are no active tokens, the remainder of the pool is never distributed.
        if (stopTime > 0 && totals.activeTokens > 0) {

            // Remaining pool might not divide equally between the active tokens, calculating
            // distributed amount without the remainder
            payouts += (totals.deposits - totals.payouts) / totals.activeTokens * totals.activeTokens;
        }

        return payouts;
    }

    /**
     * @dev Returns the sum of payouts for a particular account
     * @param account Account address
     * @return Payouts total in wei
     */
    function getAccountPayouts(address account) public view returns (uint) {
        uint interval = _getCurrentInterval();
        IntervalTotals memory totals = _getIntervalTotals(interval, account);
        uint accountPayouts = totals.accountPayouts;

        // If the payout schedule has been stopped prematurely, all deposits are distributed.
        // If there are no active tokens, the remainder of the pool is never distributed.
        if (stopTime > 0 && totals.activeTokens > 0) {
            accountPayouts += (totals.deposits - totals.payouts) / totals.activeTokens * totals.accountActiveTokens;
        }

        return accountPayouts;
    }

    /**
     * @dev Returns amount available for withdrawal
     * @param account Address to return balance for
     * @return Amount int wei
     */
    function getBalance(address account) public view returns (uint) {
        return getAccountPayouts(account) - withdrawals[account];
    }

    /**
     * @dev Withdraws all available amount
     * @param account Address to withdraw for
     *
     * Note that this method can be called by any address.
     */
    function withdraw(address payable account) external {

        uint interval = _getCurrentInterval();

        // Persists last finished interval totals to avoid having to recalculate them from the
        // deltas during the next withdrawal. Totals of the first interval should never be saved
        // to the lastWithdrawTotals map (see _getIntervalTotals for explanation).
        if (interval > 1) {
            IntervalTotals memory totals = _getIntervalTotals(interval - 1, account);

            // Converting the totals struct to a packed version before saving to storage to save gas
            lastWithdrawTotals[account] = IntervalTotalsPacked({
                deposits: uint128(totals.deposits),
                payouts: uint128(totals.payouts),
                accountPayouts: uint128(totals.accountPayouts),
                activeTokens: uint48(totals.activeTokens),
                accountActiveTokens: uint48(totals.accountActiveTokens),
                index: uint32(totals.index)
            });
        }

        uint balance = getBalance(account);
        withdrawals[account] += balance;
        account.transfer(balance);
    }

    /**
     * @dev Aggregates active token and deposit change history until the given interval
     * @param intervalIndex Interval
     * @param account Account for account-specific aggregate values
     * @return Aggregate values for the interval
     */
    function _getIntervalTotals(uint intervalIndex, address account) private view returns (IntervalTotals memory) {

        IntervalTotalsPacked storage packed = lastWithdrawTotals[account];

        // Converting packed totals struct back to unpacked one, to avoid having to do type
        // conversions in the loop below.
        IntervalTotals memory totals = IntervalTotals({
            index: packed.index,
            deposits: packed.deposits,
            payouts: packed.payouts,
            accountPayouts: packed.accountPayouts,
            activeTokens: packed.activeTokens,
            accountActiveTokens: packed.accountActiveTokens
        });

        uint prevPayout;
        uint prevAccountPayout;
        uint prevPayoutPerToken;

        // If we don't have previous totals, we need to start from intervalIndex 0 to apply the
        // active token and deposit changes of the first interval. If we have previous totals, they
        // the include all the activity of the interval already, so we start from the next one.
        //
        // Note that it's assumed all the interval total values will be 0, if the totals.index is 0.
        // This means that the totals of the first interval should never be saved to the
        // lastWithdrawTotals maps otherwise the deposits and active token changes will be counted twice.
        for (uint i = totals.index > 0 ? totals.index + 1 : 0; i <= intervalIndex; i++) {

            // Calculating payouts for the last interval data. If this is the first interval and
            // there was no previous interval totals, all these values will resolve to 0.
            prevPayoutPerToken = _getPayoutPerToken(totals);
            prevPayout = prevPayoutPerToken * totals.activeTokens;
            prevAccountPayout = totals.accountActiveTokens * prevPayoutPerToken;

            // Updating totals to represent the current interval by adding the payouts of the last
            // interval and applying changes in active token count and deposits
            totals.index = i;
            totals.payouts += prevPayout;
            totals.accountPayouts += prevAccountPayout;

            IntervalActivity storage interval = intervals[i];
            totals.deposits += interval.deposits;

            // Even though the token change value might be negative, the sum of all the changes
            // will never be negative because of the implicit contrains of the contracts (e.g. token
            // can't be transfered from an address that does not own it, or already dead token can't
            // be marked dead again). Therefore it's safe to convert the result into unsigned value,
            // after doing sum of signed values.
            totals.activeTokens = uint(int(totals.activeTokens) + interval.activeTokenChange);
            totals.accountActiveTokens = uint(int(totals.accountActiveTokens) + individualIntervals[i][account]);
        }

        return totals;
    }
}
