// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/** OpenZeppelin Dependencies */
// import "./Initializable.sol";
import "./SafeMathUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./IERC20Upgradeable.sol";
/** Local Interfaces */
import "./IToken.sol";
import "./IAuction.sol";
import "./IForeignSwap.sol";
import "./IBPD.sol";
import "./ISubBalances.sol";
import "./ISubBalancesV1.sol";


contract SubBalances is ISubBalances, Initializable, AccessControlUpgradeable {
	using SafeMathUpgradeable for uint256;

    /** Events */
    event PoolCreated(
        uint256 paydayTime,
        uint256 poolAmount
    );

    /** Structs */
    struct StakeSession {
    	address staker;
    	uint256 shares;
    	uint256 start;
    	uint256 end;
    	uint256 finishTime;
        bool[5] payDayEligible;
    	bool withdrawn;
    }

    struct SubBalance {
    	uint256 totalShares;
    	uint256 totalWithdrawAmount;
    	uint256 payDayTime;
        uint256 requiredStakePeriod;
    	bool minted;
    }

    struct Addresses {
        address mainToken;
        address foreignSwap;
        address bigPayDayPool;
        address auction;
    }

    Addresses public addresses;
    ISubBalancesV1 public subBalancesV1;

    /** Role vars */
    bytes32 public constant MIGRATOR_ROLE = keccak256("MIGRATOR_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant STAKING_ROLE = keccak256("CALLER_ROLE");
    
	uint256 public startTimestamp;
    uint256 public stepTimestamp;
    uint256 public basePeriod;
	uint256 public currentSharesTotalSupply;

    SubBalance[5] public subBalanceList;
    uint256[5] public periods;
    mapping (uint256 => StakeSession) public stakeSessions;

    bool public init_;

    /** No longer needed with initializable */
    modifier onlyManager() {
        require(hasRole(MANAGER_ROLE, _msgSender()), "Caller is not a manager");
        _;
    }
    modifier onlyMigrator() {
        require(hasRole(MIGRATOR_ROLE, _msgSender()), "Caller is not a migrator");
        _;
    }

    /** Start Init functins */
    function initialize(
        address _manager,
        address _migrator
    ) public initializer {
        _setupRole(MANAGER_ROLE, _manager);
        _setupRole(MIGRATOR_ROLE, _migrator);
    }

    function init(
        address _mainTokenAddress,
        address _foreignSwapAddress,
        address _bigPayDayPoolAddress,
        address _auctionAddress,
        address _subBalancesV1Address,
        address _stakingAddress,
        uint256 _stepTimestamp,
        uint256 _basePeriod
    ) external onlyMigrator {
        require(!init_, "NativeSwap: init is active");
        init_ = true;
        /** Setup */
        _setupRole(STAKING_ROLE, _stakingAddress);

        addresses = Addresses({
            mainToken: _mainTokenAddress,
            foreignSwap: _foreignSwapAddress,
            bigPayDayPool: _bigPayDayPoolAddress,
            auction: _auctionAddress
        });

        subBalancesV1 = ISubBalancesV1(_subBalancesV1Address);

        stepTimestamp = _stepTimestamp;
        basePeriod = _basePeriod;

        if (startTimestamp == 0) {
            startTimestamp = now;

            for (uint256 i = 0; i < subBalanceList.length; i++) {
                periods[i] = _basePeriod * (i + 1);
                SubBalance storage subBalance = subBalanceList[i];
                subBalance.payDayTime = startTimestamp.add(stepTimestamp.mul(periods[i]));
                // subBalance.payDayEnd = subBalance.payDayStart.add(stepTimestamp);
                subBalance.requiredStakePeriod = periods[i];
            }
        }
    }

    /** END INIT FUNCS */
    function getStartTimes() public view returns (uint256[5] memory startTimes) {
        for (uint256 i = 0; i < subBalanceList.length; i ++) {
            startTimes[i] = subBalanceList[i].payDayTime;
        }
    }

    function getPoolsMinted() public view returns (bool[5] memory poolsMinted) {
        for (uint256 i = 0; i < subBalanceList.length; i ++) {
            poolsMinted[i] = subBalanceList[i].minted;
        }
    }

    function getPoolsMintedAmounts() public view returns (uint256[5] memory poolsMintedAmounts) {
        for (uint256 i = 0; i < subBalanceList.length; i ++) {
            poolsMintedAmounts[i] = subBalanceList[i].totalWithdrawAmount;
        }
    }

    function getClosestYearShares() public view returns (uint256 shareAmount) {
        for (uint256 i = 0; i < subBalanceList.length; i++) {
            if (!subBalanceList[i].minted) {
                continue;
            } else {
                shareAmount = subBalanceList[i].totalShares;
                break;
            }
        }
    }

    function getStakeSession(uint256 sessionId) public view 
        returns (address staker, uint256 shares, uint256 start, uint256 end,
            uint256 finishTime, bool withdrawn, bool[5] memory payDayEligible) 
    {
        StakeSession storage stakeSession = stakeSessions[sessionId];
        
        staker = stakeSession.staker;
        shares = stakeSession.shares;
        start = stakeSession.start;
        end = stakeSession.end;
        finishTime = stakeSession.finishTime;
        withdrawn = stakeSession.withdrawn;
        payDayEligible = stakeSession.payDayEligible;
    }

    function calculateSessionPayout(
        uint256 start, 
        uint256 end, 
        uint256 finishTime, 
        uint256 shares, 
        bool[5] memory payDayEligible
    ) public view returns (uint256, uint256) {
        uint256 subBalancePayoutAmount;
        uint256[5] memory bpdRawAmounts = IBPD(addresses.bigPayDayPool).getPoolYearAmounts();
        for (uint256 i = 0; i < subBalanceList.length; i++) {
            SubBalance storage subBalance = subBalanceList[i];

            uint256 subBalanceAmount;
            uint256 addAmount;
            if (subBalance.minted) {
                subBalanceAmount = subBalance.totalWithdrawAmount;
            } else {
                (subBalanceAmount, addAmount) = _bpdAmountFromRaw(bpdRawAmounts[i]);
            }
            if (payDayEligible[i]) {
                uint256 stakerShare = shares.mul(1e18).div(subBalance.totalShares);
                uint256 stakerAmount = subBalanceAmount.mul(stakerShare).div(1e18);
                subBalancePayoutAmount = subBalancePayoutAmount.add(stakerAmount);
            }
        }

        uint256 stakingDays = end.sub(start).div(stepTimestamp);
        uint256 stakeEnd;
        if (finishTime != 0) {
            stakeEnd = finishTime;
        } else {
            stakeEnd = end;
        }

        uint256 daysStaked = stakeEnd.sub(start).div(stepTimestamp);

        // Early unstaked
        if (stakingDays > daysStaked) {
            uint256 payoutAmount = subBalancePayoutAmount.mul(daysStaked).div(stakingDays);
            uint256 earlyUnstakePenalty = subBalancePayoutAmount.sub(payoutAmount);
            return (payoutAmount, earlyUnstakePenalty);
        // Unstaked in time, no penalty
        } else if (
            daysStaked < stakingDays.add(14)
        ) {
            return (subBalancePayoutAmount, 0);
        // Unstaked late
        } else if (
            daysStaked < stakingDays.add(714)
        ) {
            uint256 daysAfterStaking = daysStaked.sub(stakingDays);
            uint256 payoutAmount = subBalancePayoutAmount.mul(uint256(714).sub(daysAfterStaking)).div(700);
            uint256 lateUnstakePenalty = subBalancePayoutAmount.sub(payoutAmount);
            return (payoutAmount, lateUnstakePenalty);
        // Too much time 
        } else {
            return (0, subBalancePayoutAmount);
        }
    }

    function withdrawPayout(uint256 sessionId) public {
        StakeSession storage stakeSession = stakeSessions[sessionId];

        require(stakeSession.finishTime != 0, "cannot withdraw before unclaim");
        require(!stakeSession.withdrawn, "already withdrawn");
        require(_msgSender() == stakeSession.staker, "caller not matching sessionId");

        (uint256 payoutAmount, uint256 penaltyAmount) 
            = calculateSessionPayout(
                stakeSession.start,
                stakeSession.end,
                stakeSession.finishTime,
                stakeSession.shares,
                stakeSession.payDayEligible
            );

        stakeSession.withdrawn = true;

        if (payoutAmount > 0) {
            IERC20Upgradeable(addresses.mainToken).transfer(_msgSender(), payoutAmount);
        }

        if (penaltyAmount > 0) {
            IERC20Upgradeable(addresses.mainToken).transfer(addresses.auction, penaltyAmount);
            IAuction(addresses.auction).callIncomeDailyTokensTrigger(penaltyAmount);
        }
    }


    function callIncomeStakerTrigger(
        address staker,
        uint256 sessionId,
        uint256 start,
        uint256 end,
        uint256 shares
    ) external override {
        require(hasRole(STAKING_ROLE, _msgSender()), "SUBBALANCES: Caller is not a staking role");
        require(end > start, "SUBBALANCES: Stake end must be after stake start");
        uint256 stakeDays = (end - start).div(stepTimestamp);

        // Skipping user if period less that year
        if (stakeDays >= basePeriod) {

            // Setting pay day eligibility for user in advance when he stakes
            bool[5] memory stakerPayDays;
            for (uint256 i = 0; i < subBalanceList.length; i++) {
                SubBalance storage subBalance = subBalanceList[i];  

                // Setting eligibility only if payday is not passed and stake end more that this pay day
                if (subBalance.payDayTime > start && end > subBalance.payDayTime) {
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
        }

        // Adding to shares
        currentSharesTotalSupply = currentSharesTotalSupply.add(shares);            
	}

    function callOutcomeStakerTrigger(
        uint256 sessionId,
        uint256 start,
        uint256 end,
        uint256 actualEnd,
        uint256 shares
    ) 
        external
        override
    {
        require(hasRole(STAKING_ROLE, _msgSender()), "SUBBALANCES: Caller is not a staking role");
        require(end > start, "SUBBALANCES: Stake end must be after stake start");
        uint256 stakeDays = (end - start).div(stepTimestamp);

        if (stakeDays >= basePeriod) {
            StakeSession storage stakeSession = stakeSessions[sessionId];

            stakeSession.finishTime = actualEnd;
            stakeSession.payDayEligible 
                = handleBpdEligibility(shares, actualEnd, stakeSession.payDayEligible);
        }

        // Substract shares from total
        if (shares > currentSharesTotalSupply) {
            currentSharesTotalSupply = 0;
        } else {
            currentSharesTotalSupply = currentSharesTotalSupply.sub(shares);
        }
    }

    function callOutcomeStakerTriggerV1(
        address staker,
        uint256 sessionId,
        uint256 start,
        uint256 end,
        uint256 actualEnd,
        uint256 shares
    ) 
        external
        override
    {
        require(hasRole(STAKING_ROLE, _msgSender()), "SUBBALANCES: Caller is not a staking role");
        require(end > start, "SUBBALANCES: Stake end must be after stake start");
        uint256 stakeDays = (end - start).div(stepTimestamp);

        if (stakeDays >= basePeriod) {
            bool[5] memory payDayEligible = subBalancesV1.getSessionEligibility(sessionId);

            payDayEligible = handleBpdEligibility(shares, actualEnd, payDayEligible);

            stakeSessions[sessionId] = StakeSession({
                staker: staker,
                shares: shares,
                start: start,
                end: end,
                finishTime: actualEnd,
                payDayEligible: payDayEligible,
                withdrawn: false
            });
        }
        
        // Substract shares from total
        if (shares > currentSharesTotalSupply) {
            currentSharesTotalSupply = 0;
        } else {
            currentSharesTotalSupply = currentSharesTotalSupply.sub(shares);
        }
    }

    function handleBpdEligibility(uint256 shares, uint256 realStakeEnd, bool[5] memory stakePayDays) 
        internal returns (bool[5] memory) 
    {
        // Rechecking eligibility of paydays
        for (uint256 i = 0; i < subBalanceList.length; i++) {
            SubBalance storage subBalance = subBalanceList[i];  

            // Removing from payday if unstaked before
            if (realStakeEnd < subBalance.payDayTime) {
                bool wasEligible = stakePayDays[i];
                stakePayDays[i] = false;

                if (wasEligible) {
                    if (shares > subBalance.totalShares) {
                        subBalance.totalShares = 0;
                    } else {
                        subBalance.totalShares = subBalance.totalShares.sub(shares);
                    }
                }
            }
        }

        return stakePayDays;
    }

    // Pool logic
    function generatePool() external returns (bool) {
    	for (uint256 i = 0; i < subBalanceList.length; i++) {
    		SubBalance storage subBalance = subBalanceList[i];

    		if (now > subBalance.payDayTime && !subBalance.minted) {
    			uint256 yearTokens = getPoolFromBPD(i);
    			(uint256 bpdTokens, uint256 addAmount) = _bpdAmountFromRaw(yearTokens);

    			IToken(addresses.mainToken).mint(address(this), addAmount);
    			subBalance.totalWithdrawAmount = bpdTokens;
    			subBalance.minted = true;

                emit PoolCreated(now, bpdTokens);
                return true;
    		}
    	}
    }

    // Pool logic
    function getPoolFromBPD(uint256 poolNumber) internal returns (uint256 poolAmount) {
    	poolAmount = IBPD(addresses.bigPayDayPool).transferYearlyPool(poolNumber);
    }

    // Pool logic
    function _bpdAmountFromRaw(uint256 yearTokenAmount) internal view returns (uint256 totalAmount, uint256 addAmount) {
    	uint256 currentTokenTotalSupply = IERC20Upgradeable(addresses.mainToken).totalSupply();

        uint256 inflation = uint256(8).mul(currentTokenTotalSupply.add(currentSharesTotalSupply)).div(36500);

        
        uint256 criticalMassCoeff = IForeignSwap(addresses.foreignSwap).getCurrentClaimedAmount().mul(1e18).div(
            IForeignSwap(addresses.foreignSwap).getTotalSnapshotAmount());

       uint256 viralityCoeff = IForeignSwap(addresses.foreignSwap).getCurrentClaimedAddresses().mul(1e18).div(
            IForeignSwap(addresses.foreignSwap).getTotalSnapshotAddresses());

        uint256 totalUprisingCoeff = uint256(1e18).add(criticalMassCoeff).add(viralityCoeff);

        totalAmount = yearTokenAmount.add(inflation).mul(totalUprisingCoeff).div(1e18);
        addAmount = totalAmount.sub(yearTokenAmount);
    }

    /* Setter methods for contract migration */
    function setNormalVariables(
        uint256 _currentSharesTotalSupply, 
        uint256[5] calldata _periods,
        uint256 _startTimestamp
    ) external onlyMigrator {
        currentSharesTotalSupply = _currentSharesTotalSupply;
        periods = _periods;
        startTimestamp = _startTimestamp;
    }

    function setSubBalanceList(
        uint256[5] calldata _totalSharesList,
        uint256[5] calldata _totalWithdrawAmountList,
        uint256[5] calldata _payDayTimeList,
        uint256[5] calldata _requiredStakePeriodList,
        bool[5] calldata _mintedList
    ) external onlyMigrator {
        for (uint256 idx = 0; idx < 5; idx = idx + 1) {
            subBalanceList[idx] = SubBalance({
                totalShares: _totalSharesList[idx],
                totalWithdrawAmount: _totalWithdrawAmountList[idx],
                payDayTime: _payDayTimeList[idx],
                requiredStakePeriod: _requiredStakePeriodList[idx],
                minted: _mintedList[idx]
            });
        }
    }

    function addStakeSessions(
        uint256[] calldata _sessionIds,
        address[] calldata _stakers,
        uint256[] calldata _sharesList,
        uint256[] calldata _startList,
        uint256[] calldata _endList,
        uint256[] calldata _finishTimeList,
        bool[] calldata _payDayEligibleList
    ) external onlyMigrator {
        for (
            uint256 sessionIdx = 0;
            sessionIdx < _sessionIds.length;
            sessionIdx = sessionIdx + 1
        ) {
            uint256 sessionId = _sessionIds[sessionIdx];
            bool[5] memory payDayEligible;
            for (uint256 boolIdx = 0; boolIdx < 5; boolIdx = boolIdx + 1) {
                payDayEligible[boolIdx] = _payDayEligibleList[5 * sessionIdx + boolIdx];
            }

            address staker = _stakers[sessionIdx];

            stakeSessions[sessionId] = StakeSession({
                staker: staker,
                shares: _sharesList[sessionIdx],
                start: _startList[sessionIdx],
                end: _endList[sessionIdx],
                finishTime: _finishTimeList[sessionIdx],
                payDayEligible: payDayEligible,
                withdrawn: false
            });
        }
    }
}
