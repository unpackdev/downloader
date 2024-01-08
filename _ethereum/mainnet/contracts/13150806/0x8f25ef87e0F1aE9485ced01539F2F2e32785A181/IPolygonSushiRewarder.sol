pragma solidity 0.8.2;
pragma experimental ABIEncoderV2;

interface IPolygonSushiRewarder {
    event LogInit();
    event LogOnReward(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        address indexed to
    );
    event LogPoolAddition(uint256 indexed pid, uint256 allocPoint);
    event LogRewardPerSecond(uint256 rewardPerSecond);
    event LogSetPool(uint256 indexed pid, uint256 allocPoint);
    event LogUpdatePool(
        uint256 indexed pid,
        uint64 lastRewardTime,
        uint256 lpSupply,
        uint256 accSushiPerShare
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function add(uint256 allocPoint, uint256 _pid) external;

    function claimOwnership() external;

    function massUpdatePools(uint256[] memory pids) external;

    function onSushiReward(
        uint256 pid,
        address _user,
        address to,
        uint256,
        uint256 lpToken
    ) external;

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function pendingToken(uint256 _pid, address _user)
        external
        view
        returns (uint256 pending);

    function pendingTokens(
        uint256 pid,
        address user,
        uint256
    )
        external
        view
        returns (address[] memory rewardTokens, uint256[] memory rewardAmounts);

    function poolIds(uint256) external view returns (uint256);

    function poolInfo(uint256)
        external
        view
        returns (
            uint128 accSushiPerShare,
            uint64 lastRewardTime,
            uint64 allocPoint
        );

    function poolLength() external view returns (uint256 pools);

    function rewardPerSecond() external view returns (uint256);

    function set(uint256 _pid, uint256 _allocPoint) external;

    function setRewardPerSecond(uint256 _rewardPerSecond) external;

    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) external;

    function updatePool(uint256 pid)
        external
        returns (ComplexRewarderTime.PoolInfo memory pool);

    function userInfo(uint256, address)
        external
        view
        returns (uint256 amount, uint256 rewardDebt);
}

interface ComplexRewarderTime {
    struct PoolInfo {
        uint128 accSushiPerShare;
        uint64 lastRewardTime;
        uint64 allocPoint;
    }
}
