// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Math.sol";
import "./EnumerableSet.sol";
import "./OwnableUpgradeable.sol";
import "./ERC20.sol";

import "./DecimalsConverter.sol";

import "./IContractsRegistry.sol";
import "./IPolicyBookRegistry.sol";
import "./IRewardsGenerator.sol";
import "./IBMICoverStaking.sol";
import "./PriceFeed.sol";

import "./AbstractDependant.sol";

import "./Globals.sol";

contract RewardsGenerator is IRewardsGenerator, OwnableUpgradeable, AbstractDependant {
    using SafeMath for uint256;
    using Math for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    IERC20 public bmiToken;
    IPolicyBookRegistry public policyBookRegistry;
    IPriceFeed public priceFeed;
    address public bmiCoverStakingAddress;
    address public bmiStakingAddress;

    uint256 public stblDecimals;

    uint256 public rewardPerBlock; // is zero by default
    uint256 public totalPoolStaked; // includes 5 decimal places

    uint256 public cumulativeSum; // includes 100 percentage
    uint256 public toUpdateRatio; // includes 100 percentage

    uint256 public startStakeBlock;
    uint256 public lastUpdateBlock;

    mapping(address => PolicyBookRewardInfo) internal _policyBooksRewards; // policybook -> policybook info
    mapping(uint256 => StakeRewardInfo) internal _stakes; // nft index -> stake info

    address public newRewardsGeneratorAddress;

    event TokensSent(address stakingAddress, uint256 amount);
    event TokensRecovered(address to, uint256 amount);
    event RewardPerBlockSet(uint256 rewardPerBlock);
    event Migrated(uint256 nftIndex, uint256 reward);

    modifier onlyBMICoverStaking() {
        require(
            _msgSender() == bmiCoverStakingAddress,
            "RewardsGenerator: Caller is not a BMICoverStaking contract"
        );
        _;
    }

    modifier onlyPolicyBooks() {
        require(
            policyBookRegistry.isPolicyBook(_msgSender()),
            "RewardsGenerator: The caller does not have access"
        );
        _;
    }

    function __RewardsGenerator_init() external initializer {
        __Ownable_init();
    }

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        bmiToken = IERC20(_contractsRegistry.getBMIContract());
        bmiStakingAddress = _contractsRegistry.getBMIStakingContract();
        bmiCoverStakingAddress = _contractsRegistry.getBMICoverStakingContract();
        policyBookRegistry = IPolicyBookRegistry(
            _contractsRegistry.getPolicyBookRegistryContract()
        );
        priceFeed = IPriceFeed(_contractsRegistry.getPriceFeedContract());

        stblDecimals = ERC20(_contractsRegistry.getUSDTContract()).decimals();
    }

    function setNewRewardsGenerator(address _newRewardsGeneratorAddress) external onlyOwner {
        newRewardsGeneratorAddress = _newRewardsGeneratorAddress;
    }

    /// @notice withdraws all underlying BMIs to the owner
    function recoverTokens() external onlyOwner {
        uint256 balance = bmiToken.balanceOf(address(this));

        bmiToken.transfer(_msgSender(), balance);

        emit TokensRecovered(_msgSender(), balance);
    }

    function sendFundsToBMIStaking(uint256 amount) external onlyOwner {
        bmiToken.transfer(bmiStakingAddress, amount);

        emit TokensSent(bmiStakingAddress, amount);
    }

    function sendFundsToBMICoverStaking(uint256 amount) external onlyOwner {
        bmiToken.transfer(bmiCoverStakingAddress, amount);

        emit TokensSent(bmiCoverStakingAddress, amount);
    }

    function setRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        rewardPerBlock = _rewardPerBlock;

        _updateCumulativeSum(address(0));

        emit RewardPerBlockSet(_rewardPerBlock);
    }

    /// @notice updates cumulative sum for a particular pool or for all of them if policyBookAddress is zero
    function _updateCumulativeSum(address policyBookAddress) internal {
        uint256 toAddSum = block.number.sub(lastUpdateBlock).mul(toUpdateRatio);
        uint256 totalStaked = totalPoolStaked;

        uint256 newCumulativeSum = cumulativeSum.add(toAddSum);

        totalStaked > 0
            ? toUpdateRatio = rewardPerBlock.mul(PERCENTAGE_100 * 10**5).div(totalStaked)
            : toUpdateRatio = 0;

        if (policyBookAddress != address(0)) {
            PolicyBookRewardInfo storage info = _policyBooksRewards[policyBookAddress];

            info.cumulativeReward = info.cumulativeReward.add(
                newCumulativeSum
                    .sub(info.cumulativeSum)
                    .mul(info.totalStaked)
                    .mul(info.rewardMultiplier)
                    .div(PERCENTAGE_100 * 10**5)
            );

            info.cumulativeSum = newCumulativeSum;
        }

        cumulativeSum = newCumulativeSum;
        lastUpdateBlock = block.number;
    }

    /// @notice calculates new cumulative average for a specific pool
    function _getNewPoolAverage(address policyBookAddress)
        internal
        view
        returns (uint256 average, uint256 toUpdateAverage)
    {
        PolicyBookRewardInfo storage info = _policyBooksRewards[policyBookAddress];

        uint256 startStakeBlockPB = info.startStakeBlock;
        uint256 lastUpdateBlockPB = info.lastUpdateBlock;
        uint256 totalStaked = info.totalStaked;

        uint256 prevStakedBlocks = lastUpdateBlockPB.sub(startStakeBlockPB);
        uint256 stakedBlocks = block.number.sub(lastUpdateBlockPB);
        uint256 allBlocks = block.number.sub(startStakeBlockPB);

        allBlocks > 0
            ? average = prevStakedBlocks
                .mul(info.average)
                .add(info.toUpdateAverage.mul(stakedBlocks))
                .div(allBlocks)
            : average = 0;

        totalStaked > 0
            ? toUpdateAverage = PERCENTAGE_100.mul(10**18).div(totalStaked)
            : toUpdateAverage = 0;
    }

    /// @notice updates an average for a specific pool
    function _updatePoolAverage(address policyBookAddress) internal {
        PolicyBookRewardInfo storage info = _policyBooksRewards[policyBookAddress];

        (info.average, info.toUpdateAverage) = _getNewPoolAverage(policyBookAddress);

        info.lastUpdateBlock = block.number;
    }

    /// @notice emulates a cumulative sum update for a specific pool and returns its accumulated reward
    function _getPoolCumulativeReward(address policyBookAddress) internal view returns (uint256) {
        PolicyBookRewardInfo storage info = _policyBooksRewards[policyBookAddress];

        uint256 toAddSum = block.number.sub(lastUpdateBlock).mul(toUpdateRatio);

        return
            info.cumulativeReward.add(
                cumulativeSum
                    .add(toAddSum)
                    .sub(info.cumulativeSum)
                    .mul(info.totalStaked)
                    .mul(info.rewardMultiplier)
                    .div(PERCENTAGE_100 * 10**5)
            );
    }

    /// @notice returns an NFT reward share of the pool (starting from the first block of pool setup)
    function _getNFTPoolShare(
        address policyBookAddress,
        uint256 nftIndex,
        uint256 currentAverage
    ) internal view returns (uint256) {
        uint256 startStakeBlockPB = _policyBooksRewards[policyBookAddress].startStakeBlock;
        uint256 allBlocks = block.number.sub(startStakeBlockPB);
        uint256 depositBlock = _stakes[nftIndex].stakeBlock.sub(startStakeBlockPB);

        return
            currentAverage
                .mul(allBlocks)
                .sub(_stakes[nftIndex].averageOnStake.mul(depositBlock))
                .mul(_stakes[nftIndex].stakeAmount)
                .div(allBlocks * 10**18);
    }

    /// @notice returns an actual reward of a particular NFT
    function _getReward(
        address policyBookAddress,
        uint256 nftIndex,
        uint256 currentAverage,
        uint256 currentCumulativeReward
    ) internal view returns (uint256) {
        return
            _stakes[nftIndex].aggregatedReward.add(
                _getNFTPoolShare(policyBookAddress, nftIndex, currentAverage)
                    .mul(currentCumulativeReward)
                    .div(PERCENTAGE_100)
            );
    }

    /// @notice updates the share of the pool based on the new rewards multiplier (also changes the share of others)
    function updatePolicyBookShare(uint256 newRewardMultiplier) external override onlyPolicyBooks {
        PolicyBookRewardInfo storage info = _policyBooksRewards[_msgSender()];

        uint256 totalStaked = info.totalStaked;

        totalPoolStaked = totalPoolStaked.sub(totalStaked.mul(info.rewardMultiplier));
        totalPoolStaked = totalPoolStaked.add(totalStaked.mul(newRewardMultiplier));

        _updateCumulativeSum(_msgSender());

        info.rewardMultiplier = newRewardMultiplier;
    }

    /// @notice aggregates specified NFTs into a single one, including the rewards
    function aggregate(
        address policyBookAddress,
        uint256[] calldata nftIndexes,
        uint256 nftIndexTo
    ) external override onlyBMICoverStaking {
        require(_stakes[nftIndexTo].stakeBlock == 0, "RewardsGenerator: Aggregator is staked");

        _updateCumulativeSum(policyBookAddress);
        _updatePoolAverage(policyBookAddress);

        uint256 currentAverage = _policyBooksRewards[policyBookAddress].average;
        uint256 currentCumulativeReward = _policyBooksRewards[policyBookAddress].cumulativeReward;
        uint256 aggregatedReward;
        uint256 aggregatedStakeAmount;

        for (uint256 i = 0; i < nftIndexes.length; i++) {
            aggregatedReward = aggregatedReward.add(
                _getReward(
                    policyBookAddress,
                    nftIndexes[i],
                    currentAverage,
                    currentCumulativeReward
                )
            );
            aggregatedStakeAmount = aggregatedStakeAmount.add(_stakes[nftIndexes[i]].stakeAmount);

            delete _stakes[nftIndexes[i]];
        }

        require(aggregatedStakeAmount > 0, "RewardsGenerator: Aggregated not staked");

        _stakes[nftIndexTo] = StakeRewardInfo(
            currentAverage,
            aggregatedReward,
            aggregatedStakeAmount,
            block.number
        );
    }

    /// @notice attaches underlying STBL tokens to an NFT and initiates rewards gain
    function stake(
        address policyBookAddress,
        uint256 nftIndex,
        uint256 amount
    ) external override onlyBMICoverStaking {
        require(_stakes[nftIndex].stakeBlock == 0, "RewardsGenerator: Already staked");

        PolicyBookRewardInfo storage info = _policyBooksRewards[policyBookAddress];

        if (info.totalStaked == 0) {
            info.lastUpdateBlock = info.startStakeBlock = block.number;

            if (info.cumulativeReward > 0) {
                info.cumulativeReward = 0;
            }
        }

        totalPoolStaked = totalPoolStaked.add(amount.mul(info.rewardMultiplier));

        _updateCumulativeSum(policyBookAddress);

        info.totalStaked = info.totalStaked.add(amount);

        _updatePoolAverage(policyBookAddress);

        _stakes[nftIndex] = StakeRewardInfo(info.average, 0, amount, block.number);
    }

    /// @notice calculates APY of the specific pool
    /// @dev returns APY% in STBL multiplied by 10**5
    function getPolicyBookAPY(address policyBookAddress)
        external
        view
        override
        onlyBMICoverStaking
        returns (uint256)
    {
        uint256 policyBookRewardMultiplier =
            _policyBooksRewards[policyBookAddress].rewardMultiplier;
        uint256 totalStakedPolicyBook =
            _policyBooksRewards[policyBookAddress].totalStaked.add(APY_TOKENS);

        uint256 rewardPerBlockPolicyBook =
            policyBookRewardMultiplier.mul(totalStakedPolicyBook).mul(rewardPerBlock).div(
                totalPoolStaked.add(policyBookRewardMultiplier.mul(APY_TOKENS))
            );

        if (rewardPerBlockPolicyBook == 0) {
            return 0;
        }

        uint256 rewardPerBlockPolicyBookSTBL =
            DecimalsConverter
                .convertTo18(priceFeed.howManyUSDTsInBMI(rewardPerBlockPolicyBook), stblDecimals)
                .mul(10**5); // 5 decimals of precision

        return
            rewardPerBlockPolicyBookSTBL.mul(BLOCKS_PER_DAY * 365).mul(100).div(
                totalStakedPolicyBook
            );
    }

    /// @dev returns PolicyBook reward per block multiplied by 10**25
    function getPolicyBookRewardPerBlock(address policyBookAddress)
        external
        view
        override
        returns (uint256)
    {
        uint256 totalStaked = totalPoolStaked;

        return
            totalStaked > 0
                ? _policyBooksRewards[policyBookAddress]
                    .rewardMultiplier
                    .mul(_policyBooksRewards[policyBookAddress].totalStaked)
                    .mul(rewardPerBlock)
                    .mul(PRECISION)
                    .div(totalStaked)
                : 0;
    }

    /// @notice returns how much STBL are using in rewards generation in the specific pool
    function getStakedPolicyBookSTBL(address policyBookAddress)
        external
        view
        override
        returns (uint256)
    {
        return _policyBooksRewards[policyBookAddress].totalStaked;
    }

    /// @notice returns how much STBL are used by an NFT
    function getStakedNFTSTBL(uint256 nftIndex) external view override returns (uint256) {
        return _stakes[nftIndex].stakeAmount;
    }

    /// @notice returns current reward of an NFT
    function getReward(address policyBookAddress, uint256 nftIndex)
        external
        view
        override
        onlyBMICoverStaking
        returns (uint256)
    {
        uint256 cumulativeRewardPB = _getPoolCumulativeReward(policyBookAddress);
        (uint256 currentAverage, ) = _getNewPoolAverage(policyBookAddress);

        return _getReward(policyBookAddress, nftIndex, currentAverage, cumulativeRewardPB);
    }

    /// @notice withdraws funds/rewards of this NFT
    /// if funds are withdrawn, updates shares of the pools
    function _withdraw(
        address policyBookAddress,
        uint256 nftIndex,
        bool onlyReward
    ) internal returns (uint256) {
        require(_stakes[nftIndex].stakeBlock > 0, "RewardsGenerator: Not staked");

        PolicyBookRewardInfo storage info = _policyBooksRewards[policyBookAddress];

        if (!onlyReward) {
            uint256 amount = _stakes[nftIndex].stakeAmount;

            totalPoolStaked = totalPoolStaked.sub(amount.mul(info.rewardMultiplier));

            _updateCumulativeSum(policyBookAddress);

            info.totalStaked = info.totalStaked.sub(amount);
        } else {
            _updateCumulativeSum(policyBookAddress);
        }

        _updatePoolAverage(policyBookAddress);

        return _getReward(policyBookAddress, nftIndex, info.average, info.cumulativeReward);
    }

    /// @notice withdraws funds (rewards + STBL tokens) of this NFT
    function withdrawFunds(address policyBookAddress, uint256 nftIndex)
        external
        override
        onlyBMICoverStaking
        returns (uint256)
    {
        uint256 reward = _withdraw(policyBookAddress, nftIndex, false);

        delete _stakes[nftIndex];

        return reward;
    }

    /// @notice withdraws rewards of this NFT
    function withdrawReward(address policyBookAddress, uint256 nftIndex)
        external
        override
        onlyBMICoverStaking
        returns (uint256)
    {
        uint256 reward = _withdraw(policyBookAddress, nftIndex, true);

        _stakes[nftIndex].averageOnStake = _policyBooksRewards[policyBookAddress].average;
        _stakes[nftIndex].aggregatedReward = 0;
        _stakes[nftIndex].stakeBlock = block.number;

        return reward;
    }

    /// @notice forcefully migrates NFTs
    /// @param offset is a starting index of an NFT to migrate
    /// @param limit is a number of NFTs to migrate starting from offset
    function migrate(uint256 offset, uint256 limit) external onlyOwner {
        require(
            newRewardsGeneratorAddress != address(0),
            "RewardsGenerator: Migration is blocked"
        );

        IBMICoverStaking bmiCoverStaking = IBMICoverStaking(bmiCoverStakingAddress);

        uint256 to = offset.add(limit);
        uint256 migratedNFTs;

        for (uint256 i = offset; i < to; i++) {
            // checks that an NFT is not migrated
            if (_stakes[i].stakeBlock == 0) {
                continue;
            }

            address policyBookAddress = bmiCoverStaking.stakingInfoByToken(i).policyBookAddress;

            uint256 reward = _withdraw(policyBookAddress, i, false);

            // (PolicyBook address, NFT index, stake amount, current reward)
            (bool succ, ) =
                newRewardsGeneratorAddress.call(
                    abi.encodeWithSignature(
                        "migrationStake(address,uint256,uint256,uint256)",
                        policyBookAddress,
                        i,
                        _stakes[i].stakeAmount,
                        reward
                    )
                );

            require(succ, "Something went wrong");

            emit Migrated(i, reward);

            delete _stakes[i];

            migratedNFTs++;
        }

        require(migratedNFTs > 0, "RewardsGenerator: Nothing to migrate");
    }
}
