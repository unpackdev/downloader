//SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

interface IUnipilotFarm {
    struct PoolInfo {
        uint256 startBlock;
        uint256 globalReward;
        uint256 lastRewardBlock;
        uint256 totalLockedLiquidity;
        uint256 rewardMultiplier;
        bool isRewardActive;
        bool isAltActive;
    }

    struct PoolAltInfo {
        address altToken;
        uint256 startBlock;
        uint256 globalReward;
        uint256 lastRewardBlock;
    }

    struct UserInfo {
        address pool;
        uint256 liquidity;
        address user;
        uint256 reward;
        uint256 altReward;
    }

    struct TempInfo {
        uint256 globalReward;
        uint256 lastRewardBlock;
        uint256 rewardMultiplier;
    }

    event Deposit(
        address pool,
        uint256 tokenId,
        uint256 liquidity,
        uint256 totalSupply,
        uint256 globalReward,
        uint256 rewardMultiplier,
        uint256 rewardPerBlock
    );
    event WithdrawReward(
        address pool,
        uint256 tokenId,
        uint256 liquidity,
        uint256 reward,
        uint256 globalReward,
        uint256 totalSupply,
        uint256 lastRewardTransferred
    );
    event WithdrawNFT(
        address pool,
        address userAddress,
        uint256 tokenId,
        uint256 totalSupply
    );

    event NewPool(
        address pool,
        uint256 rewardPerBlock,
        uint256 rewardMultiplier,
        uint256 lastRewardBlock,
        bool status
    );

    event BlacklistPool(address pool, bool status, uint256 time);

    event UpdateULM(address oldAddress, address newAddress, uint256 time);

    event UpdatePilotPerBlock(address pool, uint256 updated);

    event UpdateMultiplier(address pool, uint256 old, uint256 updated);

    event UpdateActiveAlt(address old, address updated, address pool);

    event UpdateAltState(bool old, bool updated, address pool);

    event UpdateFarmingLimit(uint256 old, uint256 updated);

    event RewardStatus(address pool, bool old, bool updated);

    event MigrateFunds(address account, address token, uint256 amount);

    event FarmingStatus(bool old, bool updated, uint256 time);

    function initializer(address[] memory pools, uint256[] memory _multipliers) external;

    function blacklistPools(address[] memory pools) external;

    function updatePilotPerBlock(uint256 value) external;

    function updateMultiplier(address pool, uint256 value) external;

    function updateULM(address _ULM) external;

    function totalUserNftWRTPool(address userAddress, address pool)
        external
        view
        returns (uint256 tokenCount, uint256[] memory tokenIds);

    function nftStatus(uint256 tokenId) external view returns (bool);

    function depositNFT(uint256 tokenId) external returns (bool);

    function withdrawNFT(uint256 tokenId) external;

    function withdrawReward(uint256 tokenId) external;

    function currentReward(uint256 _tokenId)
        external
        view
        returns (
            uint256 pilotReward,
            uint256 globalReward,
            uint256 globalAltReward,
            uint256 altReward
        );

    function toggleRewardStatus(address pool) external;

    function toggleFarmingActive() external;
}
