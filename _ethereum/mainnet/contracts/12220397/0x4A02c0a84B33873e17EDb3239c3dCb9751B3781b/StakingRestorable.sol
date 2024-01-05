// SPDX-License-Identifier: MIT

pragma solidity >=0.4.25 <0.7.0;
/** OpenZeppelin Dependencies Upgradeable */
// import "./Initializable.sol";
import "./SafeMathUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ERC20Upgradeable.sol";
/** OpenZepplin non-upgradeable Swap Token (hex3t) */
import "./IERC20.sol";
/** Local Interfaces */
import "./Staking.sol";

contract StakingRestorable is Staking {
    function init(
        address _mainTokenAddress,
        address _auctionAddress,
        address _stakingV1Address,
        uint256 _stepTimestamp,
        uint256 _lastSessionIdV1
    ) external onlyMigrator {
        require(!init_, 'Staking: init is active');
        init_ = true;
        /** Setup */
        _setupRole(EXTERNAL_STAKER_ROLE, _auctionAddress);

        addresses = Addresses({
            mainToken: _mainTokenAddress,
            auction: _auctionAddress,
            subBalances: address(0)
        });

        stakingV1 = IStakingV1(_stakingV1Address);
        stepTimestamp = _stepTimestamp;

        if (startContract == 0) {
            startContract = now;
            nextPayoutCall = startContract.add(_stepTimestamp);
        }
        if (_lastSessionIdV1 != 0) {
            lastSessionIdV1 = _lastSessionIdV1;
        }
        if (shareRate == 0) {
            shareRate = 1e18;
        }
    }

    function addStakedAmount(uint256 _staked) external onlyMigrator {
        totalStakedAmount = totalStakedAmount.add(_staked);
    }

    function addShareTotalSupply(uint256 _shares) external onlyMigrator {
        sharesTotalSupply = sharesTotalSupply.add(_shares);
    }

    // migration functions
    function setOtherVars(
        uint256 _startTime,
        uint256 _shareRate,
        uint256 _sharesTotalSupply,
        uint256 _nextPayoutCall,
        uint256 _globalPayin,
        uint256 _globalPayout,
        uint256[] calldata _payouts,
        uint256[] calldata _sharesTotalSupplyVec,
        uint256 _lastSessionId
    ) external onlyMigrator {
        startContract = _startTime;
        shareRate = _shareRate;
        sharesTotalSupply = _sharesTotalSupply;
        nextPayoutCall = _nextPayoutCall;
        globalPayin = _globalPayin;
        globalPayout = _globalPayout;
        lastSessionId = _lastSessionId;
        lastSessionIdV1 = _lastSessionId;

        for (uint256 i = 0; i < _payouts.length; i++) {
            payouts.push(
                Payout({
                    payout: _payouts[i],
                    sharesTotalSupply: _sharesTotalSupplyVec[i]
                })
            );
        }
    }

    function setSessionsOf(
        address[] calldata _wallets,
        uint256[] calldata _sessionIds
    ) external onlyMigrator {
        for (uint256 idx = 0; idx < _wallets.length; idx = idx.add(1)) {
            sessionsOf[_wallets[idx]].push(_sessionIds[idx]);
        }
    }

    function setBasePeriod(uint256 _basePeriod) external onlyMigrator {
        basePeriod = _basePeriod;
    }

    /** TESTING ONLY */
    function setLastSessionId(uint256 _lastSessionId) external onlyMigrator {
        lastSessionIdV1 = _lastSessionId.sub(1);
        lastSessionId = _lastSessionId;
    }

    function setSharesTotalSupply(uint256 _sharesTotalSupply)
        external
        onlyMigrator
    {
        sharesTotalSupply = _sharesTotalSupply;
    }

    function setTotalStakedAmount(uint256 _totalStakedAmount)
        external
        onlyMigrator
    {
        totalStakedAmount = _totalStakedAmount;
    }

    /**
     * Fix stake
     * */
    // function fixShareRateOnStake(address _staker, uint256 _stakeId)
    //     external
    //     onlyMigrator
    // {
    //     Session storage session = sessionDataOf[_staker][_stakeId]; // Get Session
    //     require(
    //         session.withdrawn == false && session.shares != 0,
    //         'STAKING: Session has already been withdrawn'
    //     );
    //     sharesTotalSupply = sharesTotalSupply.sub(session.shares); // Subtract shares total share supply
    //     session.shares = _getStakersSharesAmount(
    //         session.amount,
    //         session.start,
    //         session.end
    //     ); // update shares
    //     sharesTotalSupply = sharesTotalSupply.add(session.shares); // Add to total share suuply
    // }

    /**
     * Fix v1 unstakers
     * Unfortunately due to people not understanding that we were updating to v2, we need to fix some of our users stakes
     * This code will be removed as soon as we fix stakes
     * In order to run this code it will take at minimum 4 devs / core team to accept any stake
     * This function can not be ran by just anyone.
     */
    // function fixV1Stake(address _staker, uint256 _sessionId)
    //     external
    //     onlyMigrator
    // {
    //     require(_sessionId <= lastSessionIdV1, 'Staking: Invalid sessionId'); // Require that the sessionId we are looking for is > v1Id

    //     // Ensure that the session does not exist
    //     Session storage session = sessionDataOf[_staker][_sessionId];
    //     require(
    //         session.shares == 0 && session.withdrawn == false,
    //         'Staking: Stake already fixed and or withdrawn'
    //     );

    //     // Find the v1 stake && ensure the stake has not been withdrawn
    //     (
    //         uint256 amount,
    //         uint256 start,
    //         uint256 end,
    //         uint256 shares,
    //         uint256 firstPayout
    //     ) = stakingV1.sessionDataOf(_staker, _sessionId);

    //     require(shares == 0, 'Staking: Stake has not been withdrawn');

    //     // Get # of staking days
    //     uint256 stakingDays = (end.sub(start)).div(stepTimestamp);

    //     stakeInternalCommon(
    //         _sessionId,
    //         amount,
    //         start,
    //         end < now ? now : end,
    //         stakingDays,
    //         firstPayout,
    //         _staker
    //     );
    // }

    // Used for tests only
    function resetTotalSharesOfAccount() external {
        isVcaRegistered[msg.sender] = false;
        totalVcaRegisteredShares = totalVcaRegisteredShares.sub(
            totalSharesOf[msg.sender]
        );
        totalSharesOf[msg.sender] = 0;
    }

    /** No longer needed */
    function setShareRate(uint256 _shareRate) external onlyManager {
        shareRate = _shareRate;
    }
}
