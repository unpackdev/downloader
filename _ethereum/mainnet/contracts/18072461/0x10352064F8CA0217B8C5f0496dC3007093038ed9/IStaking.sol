// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import {IERC20Metadata} from "IERC20Metadata.sol";

import {ChainId, Timestamp} from "IBaseTypes.sol";
import {Version} from "IVersionType.sol";
import {IVersionable} from "IVersionable.sol";

import {UFixed} from "UFixedMath.sol";

import {NftId} from "IChainNft.sol";
import {IChainRegistry, ObjectType} from "IChainRegistry.sol";
import {IInstanceServiceFacade} from "IInstanceServiceFacade.sol";


interface IStaking is
    IVersionable
{

    struct StakeInfo {
        NftId id;
        NftId target;
        uint256 stakeBalance;
        uint256 rewardBalance;
        Timestamp createdAt;
        Timestamp updatedAt;
        Version version;
        Timestamp lockedUntil; // introduced with V03
    }

    event LogStakingWalletChanged(address user, address oldWallet, address newWallet);
    event LogStakingRewardReservesIncreased(address user, uint256 amount, uint256 newBalance);
    event LogStakingRewardReservesDecreased(address user, uint256 amount, uint256 newBalance);

    event LogTargetRewardRateSet(address user, NftId target, UFixed oldRewardRate, UFixed newRewardRate);
    event LogStakingRewardRateSet(address user, UFixed oldRewardRate, UFixed newRewardRate);
    event LogStakingStakingRateSet(address user, ChainId chain, address token, UFixed oldStakingRate, UFixed newStakingRate);

    event LogStakingNewStakeCreated(NftId target, address user, NftId id);
    event LogStakingStaked(NftId target, address user, NftId id, uint256 amount, uint256 newBalance);
    event LogStakingUnstaked(NftId target, address user, NftId id, uint256 amount, uint256 newBalance);
    event LogStakingRestaked(NftId oldTarget, NftId newTrget, address user, NftId stakeId, uint256 stakingAmount);

    event LogStakingRewardsUpdated(NftId id, uint256 amount, uint256 newBalance);
    event LogStakingRewardsClaimed(NftId id, uint256 amount, uint256 newBalance);

    //--- state changing functions ------------------//

    function setStakingWallet(address stakingWalletNew) external;

    function refillRewardReserves(uint256 dipAmount) external;
    function withdrawRewardReserves(uint256 dipAmount) external;

    function setRewardRate(UFixed rewardRate) external;
    function setStakingRate(ChainId chain, address token, UFixed stakingRate) external;    

    function createStake(NftId target, uint256 dipAmount) external returns(NftId id);
    function stake(NftId id, uint256 dipAmount) external;
    function createStakeWithSignature(address owner, NftId target, uint256 dipAmount, bytes32 signatureId, bytes calldata signature) external returns(NftId stakeId);
    function restake(NftId id, NftId newTarget) external;
    function restakeWithSignature(address owner, NftId stakeId, NftId newTarget, bytes32 signatureId, bytes calldata signature) external;
    function unstake(NftId id, uint256 dipAmount) external;  
    function unstakeAndClaimRewards(NftId id) external;
    function claimRewards(NftId id) external;

    //--- view and pure functions ------------------//

    function getRegistry() external view returns(IChainRegistry);
    function getMessageHelperAddress() external view returns(address messageHelperAddress);

    function maxRewardRate() external view returns(UFixed rate);
    function rewardRate() external view returns(UFixed rate);
    function rewardBalance() external view returns(uint256 dipAmount);
    function rewardReserves() external view returns(uint256 dipAmount);
    function getTargetRewardRate(NftId target) external view returns(UFixed rewardRate);

    function stakeBalance() external view returns(uint256 dipAmount);
    function stakingRate(ChainId chain, address token) external view returns(UFixed stakingRate);
    function getStakingWallet() external view returns(address stakingWallet);
    function getDip() external view returns(IERC20Metadata);

    function getInfo(NftId id) external view returns(StakeInfo memory info);

    function stakes(NftId target) external view returns(uint256 dipAmount);
    function capitalSupport(NftId target) external view returns(uint256 capitalAmount);

    function isStakingSupportedForType(ObjectType targetType) external view returns(bool isSupported);
    function isStakingSupported(NftId target) external view returns(bool isSupported);
    function isUnstakingSupported(NftId target) external view returns(bool isSupported);
    function isUnstakingAvailable(NftId stakeId) external view returns(bool isAvailable);

    function calculateRewardsIncrement(StakeInfo memory stakeInfo) external view returns(uint256 rewardsAmount);
    function calculateRewards(uint256 amount, uint256 duration) external view returns(uint256 rewardAmount);

    function calculateRequiredStaking(ChainId chain, address token, uint256 tokenAmount) external view returns(uint256 dipAmount);
    function calculateCapitalSupport(ChainId chain, address token, uint256 dipAmount) external view returns(uint256 tokenAmount);

    function toChain(uint256 chainId) external pure returns(ChainId);

    function toRate(uint256 value, int8 exp) external pure returns(UFixed);
    function rateDecimals() external pure returns(uint256 decimals);

    //--- view and pure functions (target type specific) ------------------//

    function getBundleInfo(NftId bundle)
        external
        view
        returns(
            bytes32 instanceId,
            uint256 riskpoolId,
            uint256 bundleId,
            address token,
            string memory displayName,
            IInstanceServiceFacade.BundleState bundleState,
            Timestamp expiryAt,
            bool stakingSupported,
            bool unstakingSupported,
            uint256 stakeBalance
        );

    function implementsIStaking() external pure returns(bool);
}
