// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "./IMaidCoin.sol";
import "./IRewardCalculator.sol";
import "./ISupportable.sol";
import "./IMasterChefModule.sol";

interface ITheMaster is IMasterChefModule {
    event ChangeRewardCalculator(address addr);

    event Add(
        uint256 indexed pid,
        address addr,
        bool indexed delegate,
        bool indexed mintable,
        address supportable,
        uint8 supportingRatio,
        uint256 allocPoint
    );

    event Set(uint256 indexed pid, uint256 allocPoint);
    event Deposit(uint256 indexed userId, uint256 indexed pid, uint256 amount);
    event Withdraw(uint256 indexed userId, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    event Support(address indexed supporter, uint256 indexed pid, uint256 amount);
    event Desupport(address indexed supporter, uint256 indexed pid, uint256 amount);
    event EmergencyDesupport(address indexed user, uint256 indexed pid, uint256 amount);

    event SetIsSupporterPool(uint256 indexed pid, bool indexed status);

    function initialRewardPerBlock() external view returns (uint256);

    function decreasingInterval() external view returns (uint256);

    function startBlock() external view returns (uint256);

    function maidCoin() external view returns (IMaidCoin);

    function rewardCalculator() external view returns (IRewardCalculator);

    function poolInfo(uint256 pid)
        external
        view
        returns (
            address addr,
            bool delegate,
            ISupportable supportable,
            uint8 supportingRatio,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accRewardPerShare,
            uint256 supply
        );

    function poolCount() external view returns (uint256);

    function userInfo(uint256 pid, uint256 user) external view returns (uint256 amount, uint256 rewardDebt);

    function mintableByAddr(address addr) external view returns (bool);

    function totalAllocPoint() external view returns (uint256);

    function pendingReward(uint256 pid, uint256 userId) external view returns (uint256);

    function rewardPerBlock() external view returns (uint256);

    function changeRewardCalculator(address addr) external;

    function add(
        address addr,
        bool delegate,
        bool mintable,
        address supportable,
        uint8 supportingRatio,
        uint256 allocPoint
    ) external;

    function set(uint256[] calldata pid, uint256[] calldata allocPoint) external;

    function deposit(
        uint256 pid,
        uint256 amount,
        uint256 userId
    ) external;

    function depositWithPermit(
        uint256 pid,
        uint256 amount,
        uint256 userId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function depositWithPermitMax(
        uint256 pid,
        uint256 amount,
        uint256 userId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function withdraw(
        uint256 pid,
        uint256 amount,
        uint256 userId
    ) external;

    function emergencyWithdraw(uint256 pid) external;

    function support(
        uint256 pid,
        uint256 amount,
        uint256 supportTo
    ) external;

    function supportWithPermit(
        uint256 pid,
        uint256 amount,
        uint256 supportTo,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function supportWithPermitMax(
        uint256 pid,
        uint256 amount,
        uint256 supportTo,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function desupport(uint256 pid, uint256 amount) external;

    function emergencyDesupport(uint256 pid) external;

    function mint(address to, uint256 amount) external;

    function claimSushiReward(uint256 id) external;

    function pendingSushiReward(uint256 id) external view returns (uint256);
}
