//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;


import "./RewardProgramVaultStorage.sol";
import "./VaultProxy.sol";

import "./IRewardProgramVaultEvent.sol";
import "./IRewardProgramVaultAction.sol";
import "./IUniswapV3Staker.sol";
import "./IEventLog.sol";

import "./SafeERC20.sol";
// import "./console.sol";

contract RewardProgramVault is  RewardProgramVaultStorage, VaultStorage, ProxyAccessCommon, IRewardProgramVaultEvent, IRewardProgramVaultAction
{
    using SafeERC20 for IERC20;

    modifier nonZeroAddress(address _addr) {
        require(_addr != address(0), "Vault: zero address");
        _;
    }

    modifier nonZero(uint256 _value) {
        require(_value > 0, "Vault: zero value");
        _;
    }

    ///@dev constructor
    constructor() {
    }

    /// @inheritdoc IRewardProgramVaultAction
    function changeToken(address _token) external override onlyProxyOwner nonZeroAddress(_token) {
        require(totalClaimCounts == 0, "already set claim info, cannot change token.");
        require(address(token) != _token, "same address");
        token = IERC20Minimal(_token);
    }

    /// @inheritdoc IRewardProgramVaultAction
    function changeStaker(address _staker) external override onlyProxyOwner nonZeroAddress(_staker) {
        require(address(staker) != _staker, "same address");
        staker = IUniswapV3Staker(_staker);
    }

    /// @inheritdoc IRewardProgramVaultAction
    function changePool(address _pool) external override onlyProxyOwner nonZeroAddress(_pool) {
        require(address(pool) != _pool, "same address");
        pool = IUniswapV3Pool(_pool);
    }

    /// @inheritdoc IRewardProgramVaultAction
    function changeSetting(uint256 _startWaitTime)
        external override onlyOwner
        nonZero(_startWaitTime)
    {
        startWaitTime = _startWaitTime;
    }

    /// @inheritdoc IRewardProgramVaultAction
    function initialize(
        uint256 _totalAllocatedAmount,
        uint256 _claimCounts,
        uint256[] calldata _claimTimes,
        uint256[] calldata _claimAmounts

    ) external override onlyOwner {

        require(!settingCheck, "already set");
        // require(totalClaimCounts == 0 ||
        //     (claimTimes.length > 0 && block.timestamp < claimTimes[0]) , "already set");

        require(_claimCounts > 0 && _claimTimes.length == _claimCounts && _claimAmounts.length == _claimCounts, "wrong claim data");

        require(_totalAllocatedAmount <= token.balanceOf(address(this)), "need to input the token");
        totalAllocatedAmount = _totalAllocatedAmount;
        totalClaimCounts = _claimCounts;

        uint256 totalAmount = 0;
        for(uint256 i = 0; i < _claimCounts; i++) {

            if(claimTimes.length <= i)  claimTimes.push(_claimTimes[i]);
            else claimTimes[i] = _claimTimes[i];

            if(claimAmounts.length <= i) claimAmounts.push(_claimAmounts[i]);
            else claimAmounts[i]= _claimAmounts[i];

            totalAmount += _claimAmounts[i];
        }

        require(totalAllocatedAmount == totalAmount, "check the sum of _claimAmounts");
        settingCheck = true;

        emit Initialized(_totalAllocatedAmount, _claimCounts, _claimTimes, _claimAmounts);
    }

    function initializeByProxyOwner(
        uint256 _totalAllocatedAmount,
        uint256 _claimCounts,
        uint256[] calldata _claimTimes,
        uint256[] calldata _claimAmounts

    ) external onlyProxyOwner {

        require(totalClaimCounts == 0 ||
            (claimTimes.length > 0 && block.timestamp < claimTimes[0]) , "already set");

        require(_claimCounts > 0 && _claimTimes.length == _claimCounts && _claimAmounts.length == _claimCounts, "wrong claim data");

        require(_totalAllocatedAmount <= token.balanceOf(address(this)), "need to input the token");
        totalAllocatedAmount = _totalAllocatedAmount;
        totalClaimCounts = _claimCounts;

        uint256 totalAmount = 0;

        for(uint256 j = 0; j < totalClaimCounts; j++) {
            if(claimTimes.length > 0 ) claimTimes.pop();
            if(claimAmounts.length > 0 ) claimAmounts.pop();
        }

        for(uint256 i = 0; i < _claimCounts; i++) {

            if(claimTimes.length <= i)  claimTimes.push(_claimTimes[i]);
            else claimTimes[i] = _claimTimes[i];

            if(claimAmounts.length <= i) claimAmounts.push(_claimAmounts[i]);
            else claimAmounts[i]= _claimAmounts[i];

            totalAmount += _claimAmounts[i];
        }

        require(totalAllocatedAmount == totalAmount, "check the sum of _claimAmounts");
        settingCheck = true;

        emit Initialized(_totalAllocatedAmount, _claimCounts, _claimTimes, _claimAmounts);
    }

    /// @inheritdoc IRewardProgramVaultAction
    function currentRound() public view override returns (uint256 round) {

        if(totalClaimCounts == 0 || block.timestamp < claimTimes[0]) round = 0;
        else if (totalClaimCounts > 0 && block.timestamp >= claimTimes[totalClaimCounts-1])
            round = totalClaimCounts;
        else
            for(uint256 i = 1; i < totalClaimCounts; i++) {
                if(block.timestamp < claimTimes[i])  {
                    round = i;
                    break;
                }
            }
    }

    /// @inheritdoc IRewardProgramVaultAction
    function getClaimInfo() public view override returns (
        uint256 _totalClaimCounts,
        uint256[] memory _claimTimes,
        uint256[] memory _claimAmounts,
        uint256 _totalClaimsAmount
        ) {

        return (totalClaimCounts, claimTimes, claimAmounts, totalClaimsAmount) ;
    }

    /// @inheritdoc IRewardProgramVaultAction
    function availableUseAmount(uint256 _round) public view override returns (uint256 amount) {

        if(_round == 0 || claimAmounts.length < _round) amount = 0;
        else {
            uint256 curBalance = token.balanceOf(address(this));
            uint256 expectedRemainAmount = 0;
            for(uint256 i = _round; i < claimAmounts.length; i++)
                expectedRemainAmount += claimAmounts[i];

            if(curBalance > expectedRemainAmount) amount = curBalance - expectedRemainAmount;
            else amount = 0;
        }

    }

    function createIncentive(IUniswapV3Staker.IncentiveKey memory key, uint256 reward) internal  {

        if(token.allowance(address(this), address(staker)) < reward) token.approve(address(staker), totalAllocatedAmount);

        totalClaimsAmount += reward;
        uint256 idx = totalProgramCount;
        programs[idx] = IncentiveProgram(key, reward, false);
        totalProgramCount++;

        staker.createIncentive(key, reward);

        emit IncentiveCreatedByRewardProgram(idx, address(key.rewardToken), address(key.pool), key.startTime, key.endTime, key.refundee, reward);
    }

    /// @inheritdoc IRewardProgramVaultAction
    function createProgram()
        public override nonReentrant
        nonZeroAddress(address(pool))
    {
        require( pool.token0() != address(0) && pool.token1() != address(0), "pool is zero");

        //require(block.timestamp > claimTimes[0], "Vault: not started yet");
        require(totalAllocatedAmount > totalClaimsAmount,"Vault: already All get");
        uint256 round = currentRound();
        uint256 amount = availableUseAmount(round);

        require(amount > 0, "no claimable amount");
        nowClaimRound = round;
        uint256 programDuration = getProgramDuration(nowClaimRound);
        require(programDuration > 0, "zero duration");

        createIncentive(IUniswapV3Staker.IncentiveKey(
            token,
            pool,
            block.timestamp + startWaitTime,
            block.timestamp + startWaitTime + programDuration,
            address(this)
            ),
            amount
        );
    }

    function getProgramDuration(uint256 _round) public view returns (uint256 period){

        if(_round < 1) period = 0;
        else if(_round == totalClaimCounts) {
            if(totalClaimCounts == 1) period = 30 days;
            else {
                 period = claimTimes[claimTimes.length-1] - claimTimes[claimTimes.length-2];
            }
        } else if (_round < claimTimes.length) {
            period = claimTimes[_round] - claimTimes[_round-1];
        } else period = 0;
    }

    /// @inheritdoc IRewardProgramVaultAction
    function IncentiveEnded(uint256 idx, uint256[] memory tokenIds)
        public override nonReentrant
        nonZeroAddress(address(pool))
    {
        require(totalProgramCount > 0, "no programs");
        require(idx < totalProgramCount, "invalid index");
        require(programs[idx].end == false, "already end");
        programs[idx].end = true;
        bytes32 incentiveId = keccak256(abi.encode(programs[idx].key));

        ( ,, uint96 numberOfStakes) = staker.incentives(incentiveId);

        if(numberOfStakes > 0)  require(tokenIds.length > 0, "there are stakers.");

        for(uint256 i = 0; i < tokenIds.length; i++){
            staker.unstakeToken(programs[idx].key, tokenIds[i]);
        }

        ( ,, uint96 numberOfStakesAfter) = staker.incentives(incentiveId);
        require(numberOfStakesAfter == 0, "after unstakes, there are stakers.");

        uint256 refund = staker.endIncentive(programs[idx].key);

        emit IncentiveEndedByRewardProgram(address(programs[idx].key.rewardToken), address(programs[idx].key.pool), programs[idx].key.startTime, programs[idx].key.endTime, programs[idx].key.refundee, refund);
    }

}
