// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IUnipilotFarm {
    struct UserInfo {
        uint256 reward;
        uint256 altReward;
        uint256 lpLiquidity;
        address vault;
    }

    struct VaultInfo {
        uint256 startBlock;
        uint256 lastRewardBlock;
        uint256 globalReward;
        uint256 totalLpLocked;
        uint256 multiplier;
        address stakingToken;
        RewardType reward;
    }

    struct AltInfo {
        address rewardToken;
        uint256 startBlock;
        uint256 globalReward;
        uint256 lastRewardBlock;
        uint256 multiplier;
    }

    struct Cache {
        uint256 globalReward;
        uint256 lastRewardBlock;
        uint256 multiplier;
        uint24 direction;
    }

    event Vault(
        address vault,
        uint256 rewardPerBlock,
        uint256 multiplier,
        uint256 lastRewardBlock,
        RewardType rewardType,
        address rewardToken
    );

    event RewardStatus(
        address vault,
        RewardType old,
        RewardType updated,
        address altToken
    );

    enum Direction {
        Pilot,
        Alt
    }

    enum RewardType {
        Pilot,
        Alt,
        Dual
    }

    event Deposit(
        address user,
        address vault,
        uint256 amount,
        uint256 totalLpLocked
    );

    event Withdraw(address user, address vault, uint256 amount);

    event Reward(address token, address user, address vault, uint256 reward);

    event Multiplier(
        address vault,
        address token,
        uint256 old,
        uint256 updated
    );

    event RewardPerBlock(uint256 old, uint256 updated);

    event VaultWhitelistStatus(address indexed _vault, bool status);

    event FarmingStatus(bool old, bool updated);

    event GovernanceUpdated(address old, address updated);

    event MigrateFunds(
        address newContract,
        address _tokenAddress,
        uint256 _amount
    );

    event UpdateFarmingLimit(uint256 old, uint256 updated);

    function initializer(
        address[] calldata _vault,
        uint256[] calldata _multiplier,
        RewardType[] calldata _rewardType,
        address[] calldata _rewardToken
    ) external;

    function blacklistVaults(address[] calldata _vault) external;

    function stakeLp(address vault, uint256 amount) external;

    function unstakeLp(address vault, uint256 amount) external;

    function emergencyUnstakeLp(address vault) external;

    function updateRewardPerBlock(uint256 value) external;

    function updateMultiplier(address vault, uint256 value) external;

    function updateAltMultiplier(address vault, uint256 value) external;

    function currentReward(address vault, address user)
        external
        view
        returns (
            uint256 reward,
            uint256 altReward,
            uint256 gr,
            uint256 altGr
        );

    function updateGovernance(address newGovernance) external;

    function updateRewardType(
        address _vault,
        RewardType _rewardType,
        address _altToken
    ) external;

    function migrateFunds(
        address _receiver,
        address _tokenAddress,
        uint256 _amount
    ) external;

    function updateFarmingLimit(uint256 _blockNumber) external;
}
