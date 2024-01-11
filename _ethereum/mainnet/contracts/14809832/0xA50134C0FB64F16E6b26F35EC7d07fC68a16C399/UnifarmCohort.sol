// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;
pragma abicoder v2;

import "./IUnifarmCohort.sol";
import "./IUnifarmRewardRegistryUpgradeable.sol";

// libraries
import "./CheckPointReward.sol";
import "./TransferHelpers.sol";
import "./CohortHelper.sol";

/// @title UnifarmCohort Contract
/// @author UNIFARM
/// @notice the main core cohort contract.

contract UnifarmCohort is IUnifarmCohort {
    /// @notice reciveing chain currency.
    receive() external payable {}

    /// @notice dentoes stakes
    struct Stakes {
        // farm id
        uint32 fid;
        // nft token id for this stake
        uint256 nftTokenId;
        // stake amount
        uint256 stakedAmount;
        // user start from block
        uint256 startBlock;
        // user end block
        uint256 endBlock;
        // originalOwner address.
        address originalOwner;
        // referralAddress along with stakes.
        address referralAddress;
        // true if boosted
        bool isBooster;
    }

    /// @notice factory address.
    address public immutable factory;

    /// @notice average total staking.
    mapping(uint32 => uint256) public totalStaking;

    /// @notice priorEpochATVL contains average total staking in each epochs.
    mapping(uint32 => mapping(uint256 => uint256)) public priorEpochATVL;

    /// @notice stakes map with nft Token Id.
    mapping(uint256 => Stakes) public stakes;

    /// @notice average userTotalStaking.
    mapping(address => mapping(uint256 => uint256)) public userTotalStaking;

    /**
     * @notice construct unifarm cohort contract.
     * @param factory_ factory contract address.
     */

    constructor(address factory_) {
        factory = factory_;
    }

    /**
     * @dev only owner verify
     */
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /**
     * @dev function to verify owner
     */

    function _onlyOwner() internal view {
        require(msg.sender == CohortHelper.owner(factory), 'ONA');
    }

    /**
     * @dev function helps to compute Aggregate R value
     * @param farmId farm id
     * @param startEpoch start epoch
     * @param currentEpoch current epoch
     * @param stakedAmount user staked amount
     * @param epochBlocks  number of block in epoch
     * @param userStakedBlock user staked Block.
     * @param totalStakeLimit total staking limit.
     * @param isBoosterBuyed booster buying status
     * @return r Aggregated R Value.
     */

    function computeRValue(
        uint32 farmId,
        uint256 startEpoch,
        uint256 currentEpoch,
        uint256 stakedAmount,
        uint256 epochBlocks,
        uint256 userStakedBlock,
        uint256 totalStakeLimit,
        bool isBoosterBuyed
    ) internal view returns (uint256 r) {
        uint256 i = startEpoch;
        if (i == currentEpoch) {
            r = 0;
        }
        while (i < currentEpoch) {
            uint256 eligibleBlocks;
            if (userStakedBlock > (i * epochBlocks)) {
                eligibleBlocks = ((i + 1) * epochBlocks) - userStakedBlock;
            } else {
                eligibleBlocks = epochBlocks;
            }
            if (isBoosterBuyed == false) {
                r += (stakedAmount * 1e12 * eligibleBlocks) / totalStakeLimit;
            } else {
                uint256 priorTotalStaking = priorEpochATVL[farmId][i];
                uint256 priorEpochATotalStaking = priorTotalStaking > 0 ? priorTotalStaking : totalStaking[farmId];
                r += (stakedAmount * 1e12 * eligibleBlocks) / priorEpochATotalStaking;
            }
            i++;
        }
    }

    /**
     * @inheritdoc IUnifarmCohort
     */

    function buyBooster(
        address account,
        uint256 bpid,
        uint256 tokenId
    ) external override {
        (, address nftManager, ) = CohortHelper.getStorageContracts(factory);
        require(msg.sender == nftManager || msg.sender == CohortHelper.owner(factory), 'IS');
        require(stakes[tokenId].isBooster == false, 'AB');
        stakes[tokenId].isBooster = true;
        emit BoosterBuyHistory(tokenId, account, bpid);
    }

    /**
     * @dev validate cohort staking is active or not.
     * @param registry registry address
     * @return epoch current epoch
     */

    function validateStake(address registry) internal view returns (uint256 epoch) {
        (, uint256 startBlock, uint256 endBlock, uint256 epochBlocks, , , ) = CohortHelper.getCohort(registry, address(this));
        require(block.number < endBlock, 'SC');
        epoch = CheckPointReward.getCurrentCheckpoint(startBlock, endBlock, epochBlocks);
    }

    /**
     * @inheritdoc IUnifarmCohort
     */

    function stake(
        uint32 fid,
        uint256 tokenId,
        address user,
        address referralAddress
    ) external override {
        (address registry, , ) = CohortHelper.verifyCaller(factory);

        require(user != referralAddress, 'SRNA');
        CohortHelper.validateStakeLock(registry, address(this), fid);

        uint256 epoch = validateStake(registry);

        (, address farmToken, uint256 userMinStake, uint256 userMaxStake, uint256 totalStakeLimit, , ) = CohortHelper.getCohortToken(
            registry,
            address(this),
            fid
        );

        require(farmToken != address(0), 'FTNE');
        uint256 stakeAmount = CohortHelper.getCohortBalance(farmToken, totalStaking[fid]);

        {
            userTotalStaking[user][fid] = userTotalStaking[user][fid] + stakeAmount;
            totalStaking[fid] = totalStaking[fid] + stakeAmount;
            require(stakeAmount >= userMinStake, 'UMF');
            require(userTotalStaking[user][fid] <= userMaxStake, 'UMSF');
            require(totalStaking[fid] <= totalStakeLimit, 'TSLF');
            priorEpochATVL[fid][epoch] = totalStaking[fid];
        }

        stakes[tokenId].fid = fid;
        stakes[tokenId].nftTokenId = tokenId;
        stakes[tokenId].stakedAmount = stakeAmount;
        stakes[tokenId].startBlock = block.number;
        stakes[tokenId].originalOwner = user;
        stakes[tokenId].referralAddress = referralAddress;

        emit ReferedBy(tokenId, referralAddress, stakeAmount, fid);
    }

    /**
     * @dev validate unstake or claim
     * @param registry registry address
     * @param userStakedBlock block when user staked
     * @param flag 1, if owner is caller
     * @return blocks data for cohort.
     * @return true if WToken is included on Cohort Rewards.
     */

    function validateUnstakeOrClaim(
        address registry,
        uint256 userStakedBlock,
        uint256 flag
    ) internal view returns (uint256[5] memory, bool) {
        uint256[5] memory blocksData;
        (, uint256 startBlock, uint256 endBlock, uint256 epochBlocks, , bool hasContainWrappedToken, bool hasCohortLockinAvaliable) = CohortHelper
            .getCohort(registry, address(this));

        if (hasCohortLockinAvaliable && flag == 0) {
            require(block.number > endBlock, 'CIL');
        }

        blocksData[0] = CheckPointReward.getStartCheckpoint(startBlock, userStakedBlock, epochBlocks);
        blocksData[1] = CheckPointReward.getCurrentCheckpoint(startBlock, endBlock, epochBlocks);
        blocksData[2] = endBlock;
        blocksData[3] = epochBlocks;
        blocksData[4] = startBlock;
        return (blocksData, hasContainWrappedToken);
    }

    /**
     * @dev update user totalStaking
     * @param user The Wallet address of user.
     * @param stakedAmount the amount staked by user.
     * @param fid staked farm Id
     */

    function updateUserTotalStaking(
        address user,
        uint256 stakedAmount,
        uint32 fid
    ) internal {
        userTotalStaking[user][fid] = userTotalStaking[user][fid] - stakedAmount;
    }

    /**
     * @inheritdoc IUnifarmCohort
     */

    function unStake(
        address user,
        uint256 tokenId,
        uint256 flag
    ) external override {
        (address registry, , address rewardRegistry) = CohortHelper.verifyCaller(factory);

        Stakes memory staked = stakes[tokenId];

        if (flag == 0) {
            CohortHelper.validateUnStakeLock(registry, address(this), staked.fid);
        }

        stakes[tokenId].endBlock = block.number;

        (, address farmToken, , , uint256 totalStakeLimit, , bool skip) = CohortHelper.getCohortToken(registry, address(this), staked.fid);

        (uint256[5] memory blocksData, bool hasContainWrapToken) = validateUnstakeOrClaim(registry, staked.startBlock, flag);

        uint256 rValue = computeRValue(
            staked.fid,
            blocksData[0],
            blocksData[1],
            staked.stakedAmount,
            blocksData[3],
            (staked.startBlock - (blocksData[4])),
            totalStakeLimit,
            staked.isBooster
        );
        {
            totalStaking[staked.fid] = totalStaking[staked.fid] - staked.stakedAmount;

            updateUserTotalStaking(staked.originalOwner, staked.stakedAmount, staked.fid);

            if (CohortHelper.getBlockNumber() < blocksData[2]) {
                priorEpochATVL[staked.fid][blocksData[1]] = totalStaking[staked.fid];
            }
            // transfer the stake token to user
            if (skip == false) {
                TransferHelpers.safeTransfer(farmToken, user, staked.stakedAmount);
            }
        }

        if (rValue > 0) {
            IUnifarmRewardRegistryUpgradeable(rewardRegistry).distributeRewards(
                address(this),
                user,
                staked.referralAddress,
                rValue,
                hasContainWrapToken
            );
        }

        emit Claim(staked.fid, tokenId, user, staked.referralAddress, rValue);
    }

    /**
     * @inheritdoc IUnifarmCohort
     */

    function collectPrematureRewards(address user, uint256 tokenId) external override {
        (address registry, , address rewardRegistry) = CohortHelper.verifyCaller(factory);
        Stakes memory staked = stakes[tokenId];

        CohortHelper.validateUnStakeLock(registry, address(this), staked.fid);

        uint256 stakedAmount = staked.stakedAmount;

        (uint256[5] memory blocksData, bool hasContainWrapToken) = validateUnstakeOrClaim(registry, staked.startBlock, 1);
        require(blocksData[2] > block.number, 'FNA');

        (, , , uint256 totalStakeLimit, , , ) = CohortHelper.getCohortToken(registry, address(this), staked.fid);

        stakes[tokenId].startBlock = block.number;

        uint256 rValue = computeRValue(
            staked.fid,
            blocksData[0],
            blocksData[1],
            stakedAmount,
            blocksData[3],
            (staked.startBlock - blocksData[4]),
            totalStakeLimit,
            staked.isBooster
        );

        require(rValue > 0, 'NRM');

        IUnifarmRewardRegistryUpgradeable(rewardRegistry).distributeRewards(address(this), user, staked.referralAddress, rValue, hasContainWrapToken);

        emit Claim(staked.fid, tokenId, user, staked.referralAddress, rValue);
    }

    /**
     * @inheritdoc IUnifarmCohort
     */

    function setPortionAmount(uint256 tokenId, uint256 stakedAmount) external onlyOwner {
        stakes[tokenId].stakedAmount = stakedAmount;
    }

    /**
     * @inheritdoc IUnifarmCohort
     */

    function disableBooster(uint256 tokenId) external onlyOwner {
        stakes[tokenId].isBooster = false;
    }

    /**
     * @inheritdoc IUnifarmCohort
     */

    function safeWithdrawEth(address withdrawableAddress, uint256 amount) external onlyOwner returns (bool) {
        require(withdrawableAddress != address(0), 'IWA');
        TransferHelpers.safeTransferParentChainToken(withdrawableAddress, amount);
        return true;
    }

    /**
     * @inheritdoc IUnifarmCohort
     */

    function safeWithdrawAll(
        address withdrawableAddress,
        address[] memory tokens,
        uint256[] memory amounts
    ) external onlyOwner {
        require(withdrawableAddress != address(0), 'IWA');
        require(tokens.length == amounts.length, 'SF');
        uint8 numberOfTokens = uint8(tokens.length);
        uint8 i = 0;
        while (i < numberOfTokens) {
            TransferHelpers.safeTransfer(tokens[i], withdrawableAddress, amounts[i]);
            i++;
        }
    }

    /**
     * @inheritdoc IUnifarmCohort
     */

    function viewStakingDetails(uint256 tokenId)
        public
        view
        override
        returns (
            uint32 fid,
            uint256 nftTokenId,
            uint256 stakedAmount,
            uint256 startBlock,
            uint256 endBlock,
            address originalOwner,
            address referralAddress,
            bool isBooster
        )
    {
        Stakes memory userStake = stakes[tokenId];
        return (
            userStake.fid,
            userStake.nftTokenId,
            userStake.stakedAmount,
            userStake.startBlock,
            userStake.endBlock,
            userStake.originalOwner,
            userStake.referralAddress,
            userStake.isBooster
        );
    }
}
