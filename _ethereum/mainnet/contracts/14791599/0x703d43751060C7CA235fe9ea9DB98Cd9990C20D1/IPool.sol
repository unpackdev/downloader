// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

interface IPool {
    /* EVENTS */
    event PoolAdded(
        uint256 pid,
        address stakeToken,
        uint256 allocPoint,
        uint256 startBlock,
        uint256 bonusMultiplier,
        uint256 bonusEndBlock,
        uint256 minStakePeriod
    );

    event AllocationSet(uint256 pid, uint256 allocPoint);

    event RewardPerBlockSet(uint256 rewardPerBlock);

    event StartingBlockSet(uint256 pid, uint256 startBlock);

    event MinStakePeriodSet(uint256 pid, uint256 minStakePeriod);

    event AddedRewardAmount(uint256 pid, uint256 oldAmount, uint256 newAmount);

    event BonusDataSet(uint256 pid, uint256 bonusEndBlock, uint256 bonusMultiplier);

    event AdminTokenRecovery(address token, uint256 amount);

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);

    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    /* public var getters */

    function rewardToken() external view returns (address);

    function rewardPerBlock() external view returns (uint256);

    function mintable() external view returns (bool);

    function treasury() external view returns (address);

    function nativeToken() external view returns (address);

    function PRECISION_FACTOR() external view returns (uint256);

    function staked(address) external view returns (bool);

    function poolInfo(uint256)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool
        );

    function userInfo(uint256, address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function totalAllocPoint() external view returns (uint256);

    /* PUBLIC GETTERS */

    function poolLength() external view returns (uint256);

    function getMultiplier(
        uint256 _pid,
        uint256 _from,
        uint256 _to
    ) external view returns (uint256);

    // should change back to pendingReward for live deploy
    function pendingReward(uint256 _pid, address _user) external view returns (uint256);

    /* PUBLIC */

    function deposit(uint256 _pid, uint256 _amount) external payable;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function emergencyWithdraw(uint256 _pid) external;

    function massUpdatePools() external;

    function updatePool(uint256 _pid) external;

    /* ADMIN/GOVERNANCE */

    function initialize(
        address _rewardToken,
        uint256 _rewardPerBlock,
        address _treasury,
        address _nativeToken,
        uint256 _nativeAllocPoint,
        uint256 _nativeStartBlock,
        uint256 _nativeBonusMultiplier,
        uint256 _nativeBonusEndBlock,
        uint256 _nativeMinStakePeriod,
        address _manager
    ) external;

    function add(
        address _stakeToken,
        uint256 _allocPoint,
        uint256 _startBlock,
        uint256 _bonusMultiplier,
        uint256 _bonusEndBlock,
        uint256 _minStakePeriod,
        uint256 _rewardAmount,
        bool _withUpdate,
        bool _isLpToken
    ) external;

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external;

    function updateRewardPerBlock(uint256 _rewardPerBlock) external;

    function updateStart(uint256 _pid, uint256 _startBlock) external;

    // function updateMinStakePeriod(uint256 _pid, uint256 _minStakePeriod) external;

    function updateBonus(
        uint256 _pid,
        uint256 _bonusEndBlock,
        uint256 _bonusMultiplier
    ) external;

    function addRewardAmount(uint256 _pid, uint256 _rewardAmount) external;

    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external;
}
