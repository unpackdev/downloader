// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import {Version, toVersion, toVersionPart} from "IVersionType.sol";
import {Timestamp, blockTimestamp, toTimestamp, zeroTimestamp} from "IBaseTypes.sol";
import {UFixed} from "UFixedMath.sol";

import {IChainRegistry, ObjectType} from "ChainRegistryV01.sol";
import {NftId} from "IChainNft.sol";

import {StakingV02} from "StakingV02.sol";
import {StakingMessageHelper} from "StakingMessageHelper.sol";
import {RewardHelper} from "RewardHelper.sol";


contract StakingV03 is
    StakingV02
{

    struct RewardInfo {
        UFixed rewardRate;
        Timestamp createdAt;
        Timestamp updatedAt;
    }

    StakingMessageHelper internal _messageHelper;
    RewardHelper internal _rewardHelper;

    mapping(NftId target => RewardInfo rewardRate) internal _targetRewardRate;


    // IMPORTANT 1. version needed for upgradable versions
    // _activate is using this to check if this is a new version
    // and if this version is higher than the last activated version
    function version()
        public
        virtual override
        pure
        returns(Version)
    {
        return toVersion(
            toVersionPart(1),
            toVersionPart(1),
            toVersionPart(1));
    }


    // IMPORTANT 2. activate implementation needed
    // is used by proxy admin in its upgrade function
    function activate(address implementation, address activatedBy)
        external 
        virtual override
    { 
        // keep track of version history
        // do some upgrade checks
        _activate(implementation, activatedBy);

        // upgrade version
        _version = version();
    }


    function setMessageHelper(address stakingMessageHelper)
        external
        onlyOwner
    {
        _messageHelper = StakingMessageHelper(stakingMessageHelper);
    }


    function setRewardHelper(address rewardHelper)
        external
        onlyOwner
    {
        _rewardHelper = RewardHelper(rewardHelper);
    }


    function setRewardRate(UFixed newRewardRate) external virtual override onlyOwner {
        _rewardRate = newRewardRate;
        _rewardHelper.setRewardRate(newRewardRate);
    }


    function setTargetRewardRate(NftId target, UFixed newRewardRate) external virtual onlyOwner {
        _rewardHelper.setTargetRewardRate(target, newRewardRate);
    }

    function maxRewardRate() external virtual override view returns (UFixed) {
        return _rewardRateMax;
    }

    function rewardRate() external virtual override view returns (UFixed) {
        return _rewardHelper.rewardRate();
    }

    function getTargetRewardRate(NftId target) public virtual override view returns(UFixed) {
        return _rewardHelper.getTargetRewardRate(target);
    }

    function updateRewards(NftId stakeId)
        external
        virtual
        onlyOwner
    {
        // input validation (stake needs to exist)
        StakeInfo storage info = _info[stakeId];
        require(info.createdAt > zeroTimestamp(), "ERROR:STK-320:STAKE_NOT_EXISTING");

        _updateRewards(info);
    }


    function createStakeWithSignature(
        address owner,
        NftId target, 
        uint256 dipAmount,
        bytes32 signatureId,
        bytes calldata signature
    )
        external
        virtual override
        returns(NftId stakeId)
    {
        _messageHelper.processStakeSignature(
            owner,
            target,
            dipAmount,
            signatureId,
            signature);

        return _createStake(owner, target, dipAmount);
    }


    function createStake(NftId target, uint256 dipAmount)
        external
        virtual override
        returns(NftId stakeId)
    {
        return _createStake(msg.sender, target, dipAmount);
    }


    function stake(NftId stakeId, uint256 dipAmount)
        public
        virtual override
    {
        _stake(msg.sender, stakeId, dipAmount);
    }


    function restakeWithSignature(
        address owner,
        NftId stakeId, 
        NftId newTarget,
        bytes32 signatureId,
        bytes calldata signature
    )
        external
        virtual override
    {
        _messageHelper.processRestakeSignature(
            owner,
            stakeId,
            newTarget,
            signatureId,
            signature);

        return _restake(owner, stakeId, newTarget);
    }


    function restake(NftId stakeId, NftId newTarget)
        external
        virtual override
        onlyStakeOwner(stakeId)        
    {
        // only owner may restake
        address owner = msg.sender;

        return _restake(owner, stakeId, newTarget);
    }


    function _restake(address owner, NftId stakeId, NftId newTarget)
        internal
        virtual
    {
        // ensure unstaking is possible
        require(isUnstakingAvailable(stakeId), "ERROR:STK-160:UNSTAKING_NOT_SUPPORTED");

        // staking needs to be possible (might change over time)
        require(isStakingSupported(newTarget), "ERROR:STK-161:STAKING_NOT_SUPPORTED");

        // update rewards of old stake
        StakeInfo storage oldInfo = _info[stakeId];
        _updateRewards(oldInfo);

        // remove stake balance from old target
        _targetStakeBalance[oldInfo.target] -= oldInfo.stakeBalance;

        // calculate new staking amount
        uint256 newStakingAmount = oldInfo.stakeBalance + oldInfo.rewardBalance;

        // update stake, reward balance and reward reserves
        require(_rewardReserves >= oldInfo.rewardBalance, "ERROR:STK-162:REWRD_RESERVES_INSUFFICIENT");
        _rewardReserves -= oldInfo.rewardBalance;
        _rewardBalance -= oldInfo.rewardBalance;
        _stakeBalance += oldInfo.rewardBalance;
 
        // adapt old info
        oldInfo.stakeBalance = 0;
        oldInfo.rewardBalance = 0;
        oldInfo.updatedAt = blockTimestamp();

        // add/create new info
        stakeId = _registry.registerStake(newTarget, owner);
        StakeInfo storage newInfo = _info[stakeId];
        newInfo.id = stakeId;
        newInfo.target = newTarget;
        newInfo.stakeBalance = newStakingAmount;
        newInfo.rewardBalance = 0;
        newInfo.createdAt = blockTimestamp();
        newInfo.updatedAt = blockTimestamp();
        newInfo.lockedUntil = calculateLockingUntil(newTarget);
        newInfo.version = version();

        // add staking amount to new target
        _targetStakeBalance[newInfo.target] += newStakingAmount;

        // restaking leg entry
        emit LogStakingRestaked(oldInfo.target, newInfo.target, owner, stakeId, newStakingAmount);
    }


    function getMessageHelperAddress()
        external
        virtual override
        view
        returns(address messageHelperAddress)
    {
        return address(_messageHelper);
    }


    function isUnstakingAvailable(NftId stakeId)
        public
        virtual override
        view 
        returns(bool isAvailable)
    {
        StakeInfo memory info = _info[stakeId];
        if(info.lockedUntil > zeroTimestamp() && blockTimestamp() >= info.lockedUntil) {
            return true;
        }

        return isUnstakingSupported(info.target);
    }


    function calculateLockingUntil(NftId target)
        public
        virtual
        view
        returns(Timestamp lockedUntil)
    {
        IChainRegistry.NftInfo memory info = _registry.getNftInfo(target);

        if(info.objectType == _registryConstant.BUNDLE()) {
            (,,,,, uint256 expiryAt) = _registry.decodeBundleData(target);
            return toTimestamp(expiryAt);
        }

        return zeroTimestamp();
    }


    function calculateRewardsIncrement(StakeInfo memory info)
        public 
        virtual override
        view
        returns(uint256 rewardsAmount)
    {
        /* solhint-disable not-rely-on-time */
        require(block.timestamp >= toInt(info.updatedAt), "ERROR:STK-200:UPDATED_AT_IN_THE_FUTURE");
        uint256 timeSinceLastUpdate = block.timestamp - toInt(info.updatedAt);
        /* solhint-enable not-rely-on-time */

        // TODO potentially reduce time depending on the time when the bundle has been closed

        UFixed rate = getTargetRewardRate(info.target);
        rewardsAmount = _rewardHelper.calculateRewards(info.stakeBalance, timeSinceLastUpdate, rate);
    }


    function _createStake(
        address owner,
        NftId target, 
        uint256 dipAmount
    )
        internal
        virtual
        returns(NftId stakeId)
    {
        // no validation here, validation is done via calling stake() at the end
        stakeId = _registry.registerStake(target, owner);

        StakeInfo storage info = _info[stakeId];
        info.id = stakeId;
        info.target = target;
        info.stakeBalance = 0;
        info.rewardBalance = 0;
        info.createdAt = blockTimestamp();
        info.lockedUntil = calculateLockingUntil(target);
        info.version = version();

        _stake(owner, stakeId, dipAmount);

        emit LogStakingNewStakeCreated(target, owner, stakeId);
    }


    function _stake(address owner, NftId stakeId, uint256 dipAmount)
        internal
        virtual
    {
        // input validation (stake needs to exist)
        StakeInfo storage info = _info[stakeId];
        require(info.createdAt > zeroTimestamp(), "ERROR:STK-150:STAKE_NOT_EXISTING");
        require(dipAmount > 0, "ERROR:STK-151:STAKING_AMOUNT_ZERO");

        // staking needs to be possible (might change over time)
        require(isStakingSupported(info.target), "ERROR:STK-152:STAKING_NOT_SUPPORTED");

        // update stake info
        _updateRewards(info);
        _increaseStakes(info, dipAmount);
        _collectDip(owner, dipAmount);

        emit LogStakingStaked(info.target, owner, stakeId, dipAmount, info.stakeBalance);
    }


    function _unstake(
        NftId id,
        address user, 
        uint256 amount

    ) 
        internal
        virtual override
    {
        StakeInfo storage info = _info[id];
        require(_canUnstake(info), "ERROR:STK-250:UNSTAKE_NOT_SUPPORTED");
        require(amount > 0, "ERROR:STK-251:UNSTAKE_AMOUNT_ZERO");

        _updateRewards(info);

        bool unstakeAll = (amount == type(uint256).max);
        if(unstakeAll) {
            amount = info.stakeBalance;
        }

        _decreaseStakes(info, amount);
        _withdrawDip(user, amount);

        emit LogStakingUnstaked(
            info.target,
            user,
            info.id,
            amount,
            info.stakeBalance
        );

        if(unstakeAll) {
            _claimRewards(user, info);
        }
    }


    function _canUnstake(StakeInfo storage info)
        internal
        virtual
        view
        returns(bool canUnstake)
    {
        if(info.lockedUntil > zeroTimestamp() && blockTimestamp() >= info.lockedUntil) {
            return true;
        }

        return this.isUnstakingSupported(info.target);
    }

}
