// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IBooster {
    struct PoolInfo {
        address lptoken;
        address token;
        address gauge;
        address crvRewards;
        address stash;
        bool shutdown;
    }

    function minter() external view returns (address);

    function poolInfo(uint256 i) external view returns (PoolInfo memory);

    function poolLength() external view returns (uint256);

    function deposit(uint256 pid, uint256 lp, bool stake) external;

    function withdraw(uint256 pid, uint256 lp) external;

    function withdrawAll(uint256 pid) external;
}
