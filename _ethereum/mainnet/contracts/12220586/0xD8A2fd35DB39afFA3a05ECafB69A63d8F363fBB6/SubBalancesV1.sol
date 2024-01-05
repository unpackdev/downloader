// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./AccessControl.sol";
import "./ITokenV1.sol";
import "./IAuctionV1.sol";
import "./IForeignSwapV1.sol";
import "./IBPDV1.sol";
import "./ISubBalancesV1.sol";

contract SubBalancesV1 is ISubBalancesV1, AccessControl {
    using SafeMath for uint256;

    event PoolCreated(uint256 paydayTime, uint256 poolAmount);

    bytes32 public constant SETTER_ROLE = keccak256('SETTER_ROLE');
    bytes32 public constant STAKING_ROLE = keccak256('CALLER_ROLE');

    struct StakeSession {
        address staker;
        uint256 shares;
        // uint256 sessionId;
        uint256 start;
        uint256 end;
        uint256 finishTime;
        bool[5] payDayEligible;
        bool withdrawn;
    }

    struct SubBalance {
        // mapping (address => uint256[]) userStakings;
        // mapping (uint256 => StakeSession) stakeSessions;
        uint256 totalShares;
        uint256 totalWithdrawAmount;
        uint256 payDayTime;
        // uint256 payDayEnd;
        uint256 requiredStakePeriod;
        bool minted;
    }

    SubBalance[5] public subBalanceList;

    address public mainToken;
    address public foreignSwap;
    address public bigPayDayPool;
    address public auction;
    uint256 public startTimestamp;
    uint256 public stepTimestamp;
    uint256 public basePeriod;
    uint256[5] public PERIODS;

    uint256 public currentSharesTotalSupply;

    // Users
    mapping(address => uint256[]) userStakings;
    mapping(uint256 => StakeSession) stakeSessions;

    function init(
        address _mainToken,
        address _foreignSwap,
        address _bigPayDayPool,
        address _auction,
        address _staking,
        uint256 _stepTimestamp,
        uint256 _basePeriod
    ) public {
        _setupRole(STAKING_ROLE, _staking);
        mainToken = _mainToken;
        foreignSwap = _foreignSwap;
        bigPayDayPool = _bigPayDayPool;
        auction = _auction;
        stepTimestamp = _stepTimestamp;
        basePeriod = _basePeriod;
        startTimestamp = now;

        for (uint256 i = 0; i < subBalanceList.length; i++) {
            PERIODS[i] = _basePeriod.mul(i.add(1));
            SubBalance storage subBalance = subBalanceList[i];
            subBalance.payDayTime = startTimestamp.add(
                stepTimestamp.mul(PERIODS[i])
            );
            // subBalance.payDayEnd = subBalance.payDayStart.add(stepTimestamp);
            subBalance.requiredStakePeriod = PERIODS[i];
        }
    }

    function getStartTimes()
        public
        view
        returns (uint256[5] memory startTimes)
    {
        for (uint256 i = 0; i < subBalanceList.length; i++) {
            startTimes[i] = subBalanceList[i].payDayTime;
        }
    }

    function getPoolsMinted() public view returns (bool[5] memory poolsMinted) {
        for (uint256 i = 0; i < subBalanceList.length; i++) {
            poolsMinted[i] = subBalanceList[i].minted;
        }
    }

    function getPoolsMintedAmounts()
        public
        view
        returns (uint256[5] memory poolsMintedAmounts)
    {
        for (uint256 i = 0; i < subBalanceList.length; i++) {
            poolsMintedAmounts[i] = subBalanceList[i].totalWithdrawAmount;
        }
    }

    function getClosestYearShares() public view returns (uint256 shareAmount) {
        for (uint256 i = 0; i < subBalanceList.length; i++) {
            if (!subBalanceList[i].minted) {
                continue;
            } else {
                shareAmount = subBalanceList[i].totalShares;
                return shareAmount;
            }

            // return 0;
        }
    }

    function getSessionStats(uint256 sessionId)
        public
        view
        returns (
            address staker,
            uint256 shares,
            uint256 start,
            uint256 sessionEnd,
            bool withdrawn
        )
    {
        StakeSession storage stakeSession = stakeSessions[sessionId];
        staker = stakeSession.staker;
        shares = stakeSession.shares;
        start = stakeSession.start;
        if (stakeSession.finishTime > 0) {
            sessionEnd = stakeSession.finishTime;
        } else {
            sessionEnd = stakeSession.end;
        }
        withdrawn = stakeSession.withdrawn;
    }

    function getSessionEligibility(uint256 sessionId)
        public
        view
        returns (bool[5] memory stakePayDays)
    {
        StakeSession storage stakeSession = stakeSessions[sessionId];
        for (uint256 i = 0; i < subBalanceList.length; i++) {
            stakePayDays[i] = stakeSession.payDayEligible[i];
        }
    }

    function calculateSessionPayout(uint256 sessionId)
        public
        view
        returns (uint256, uint256)
    {
        StakeSession storage stakeSession = stakeSessions[sessionId];

        uint256 subBalancePayoutAmount;
        uint256[5] memory bpdRawAmounts =
            IBPDV1(bigPayDayPool).getPoolYearAmounts();
        for (uint256 i = 0; i < subBalanceList.length; i++) {
            SubBalance storage subBalance = subBalanceList[i];

            uint256 subBalanceAmount;
            uint256 addAmount;
            if (subBalance.minted) {
                subBalanceAmount = subBalance.totalWithdrawAmount;
            } else {
                (subBalanceAmount, addAmount) = _bpdAmountFromRaw(
                    bpdRawAmounts[i]
                );
            }
            if (stakeSession.payDayEligible[i]) {
                uint256 stakerShare =
                    stakeSession.shares.mul(1e18).div(subBalance.totalShares);
                uint256 stakerAmount =
                    subBalanceAmount.mul(stakerShare).div(1e18);
                subBalancePayoutAmount = subBalancePayoutAmount.add(
                    stakerAmount
                );
            }
        }

        uint256 stakingDays =
            stakeSession.end.sub(stakeSession.start).div(stepTimestamp);
        uint256 stakeEnd;
        if (stakeSession.finishTime != 0) {
            stakeEnd = stakeSession.finishTime;
        } else {
            stakeEnd = stakeSession.end;
        }

        uint256 daysStaked =
            stakeEnd.sub(stakeSession.start).div(stepTimestamp);

        // Early unstaked
        if (stakingDays > daysStaked) {
            uint256 payoutAmount =
                subBalancePayoutAmount.mul(daysStaked).div(stakingDays);
            uint256 earlyUnstakePenalty =
                subBalancePayoutAmount.sub(payoutAmount);
            return (payoutAmount, earlyUnstakePenalty);
            // Unstaked in time, no penalty
        } else if (
            stakingDays <= daysStaked && daysStaked < stakingDays.add(14)
        ) {
            return (subBalancePayoutAmount, 0);
            // Unstaked late
        } else if (
            stakingDays.add(14) <= daysStaked &&
            daysStaked < stakingDays.add(714)
        ) {
            uint256 daysAfterStaking = daysStaked.sub(stakingDays);
            uint256 payoutAmount =
                subBalancePayoutAmount
                    .mul(uint256(714).sub(daysAfterStaking))
                    .div(700);
            uint256 lateUnstakePenalty =
                subBalancePayoutAmount.sub(payoutAmount);
            return (payoutAmount, lateUnstakePenalty);
            // Too much time
        } else if (stakingDays.add(714) <= daysStaked) {
            return (0, subBalancePayoutAmount);
        }

        return (0, 0);
    }

    function withdrawPayout(uint256 sessionId) public {
        StakeSession storage stakeSession = stakeSessions[sessionId];

        require(stakeSession.finishTime != 0, 'cannot withdraw before unclaim');
        require(!stakeSession.withdrawn, 'already withdrawn');
        require(
            _msgSender() == stakeSession.staker,
            'caller not matching sessionId'
        );
        (uint256 payoutAmount, uint256 penaltyAmount) =
            calculateSessionPayout(sessionId);

        stakeSession.withdrawn = true;

        if (payoutAmount > 0) {
            IERC20(mainToken).transfer(_msgSender(), payoutAmount);
        }

        if (penaltyAmount > 0) {
            IERC20(mainToken).transfer(auction, penaltyAmount);
            IAuctionV1(auction).callIncomeDailyTokensTrigger(penaltyAmount);
        }
    }

    function callIncomeStakerTrigger(
        address staker,
        uint256 sessionId,
        uint256 start,
        uint256 end,
        uint256 shares
    ) external override {
        require(
            end > start,
            'SUBBALANCES: Stake end must be after stake start'
        );
        uint256 stakeDays = end.sub(start).div(stepTimestamp);

        // Skipping user if period less that year
        if (stakeDays >= basePeriod) {
            // Setting pay day eligibility for user in advance when he stakes
            bool[5] memory stakerPayDays;
            for (uint256 i = 0; i < subBalanceList.length; i++) {
                SubBalance storage subBalance = subBalanceList[i];

                // Setting eligibility only if payday is not passed and stake end more that this pay day
                if (
                    subBalance.payDayTime > start && end > subBalance.payDayTime
                ) {
                    stakerPayDays[i] = true;

                    subBalance.totalShares = subBalance.totalShares.add(shares);
                }
            }

            // Saving user
            stakeSessions[sessionId] = StakeSession({
                staker: staker,
                shares: shares,
                start: start,
                end: end,
                finishTime: 0,
                payDayEligible: stakerPayDays,
                withdrawn: false
            });
            userStakings[staker].push(sessionId);
        }

        // Adding to shares
        currentSharesTotalSupply = currentSharesTotalSupply.add(shares);
    }

    function callOutcomeStakerTrigger(
        address staker,
        uint256 sessionId,
        uint256 start,
        uint256 end,
        uint256 shares
    ) external override {
        (staker);
        require(
            end > start,
            'SUBBALANCES: Stake end must be after stake start'
        );
        uint256 stakeDays = end.sub(start).div(stepTimestamp);
        uint256 realStakeEnd = now;
        // uint256 daysStaked = realStakeEnd.sub(stakeStart).div(stepTimestamp);

        if (stakeDays >= basePeriod) {
            StakeSession storage stakeSession = stakeSessions[sessionId];

            // Rechecking eligibility of paydays
            for (uint256 i = 0; i < subBalanceList.length; i++) {
                SubBalance storage subBalance = subBalanceList[i];

                // Removing from payday if unstaked before
                if (realStakeEnd < subBalance.payDayTime) {
                    bool wasEligible = stakeSession.payDayEligible[i];
                    stakeSession.payDayEligible[i] = false;

                    if (wasEligible) {
                        if (shares > subBalance.totalShares) {
                            subBalance.totalShares = 0;
                        } else {
                            subBalance.totalShares = subBalance.totalShares.sub(
                                shares
                            );
                        }
                    }
                }
            }

            // Setting real stake end
            stakeSessions[sessionId].finishTime = realStakeEnd;
        }

        // Substract shares from total
        if (shares > currentSharesTotalSupply) {
            currentSharesTotalSupply = 0;
        } else {
            currentSharesTotalSupply = currentSharesTotalSupply.sub(shares);
        }
    }

    // Pool logic
    function generatePool() external returns (bool) {
        for (uint256 i = 0; i < subBalanceList.length; i++) {
            SubBalance storage subBalance = subBalanceList[i];

            if (now > subBalance.payDayTime && !subBalance.minted) {
                uint256 yearTokens = getPoolFromBPD(i);
                (uint256 bpdTokens, uint256 addAmount) =
                    _bpdAmountFromRaw(yearTokens);

                ITokenV1(mainToken).mint(address(this), addAmount);
                subBalance.totalWithdrawAmount = bpdTokens;
                subBalance.minted = true;

                emit PoolCreated(now, bpdTokens);
                return true;
            }
        }
    }

    // Pool logic
    function getPoolFromBPD(uint256 poolNumber)
        internal
        returns (uint256 poolAmount)
    {
        poolAmount = IBPDV1(bigPayDayPool).transferYearlyPool(poolNumber);
    }

    // Pool logic
    function _bpdAmountFromRaw(uint256 yearTokenAmount)
        internal
        view
        returns (uint256 totalAmount, uint256 addAmount)
    {
        uint256 currentTokenTotalSupply = IERC20(mainToken).totalSupply();

        uint256 inflation =
            uint256(8)
                .mul(currentTokenTotalSupply.add(currentSharesTotalSupply))
                .div(36500);

        uint256 criticalMassCoeff =
            IForeignSwapV1(foreignSwap).getCurrentClaimedAmount().mul(1e18).div(
                IForeignSwapV1(foreignSwap).getTotalSnapshotAmount()
            );

        uint256 viralityCoeff =
            IForeignSwapV1(foreignSwap)
                .getCurrentClaimedAddresses()
                .mul(1e18)
                .div(IForeignSwapV1(foreignSwap).getTotalSnapshotAddresses());

        uint256 totalUprisingCoeff =
            uint256(1e18).add(criticalMassCoeff).add(viralityCoeff);

        totalAmount = yearTokenAmount
            .add(inflation)
            .mul(totalUprisingCoeff)
            .div(1e18);
        addAmount = totalAmount.sub(yearTokenAmount);
    }
}
