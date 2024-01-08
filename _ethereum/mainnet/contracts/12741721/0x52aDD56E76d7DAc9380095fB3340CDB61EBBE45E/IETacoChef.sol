pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT


interface IETacoChef {
    function poolLength() external view returns (uint256);

    function startBlock() external view returns (uint256);

    function setProvider(address) external;

    function setApi(uint256) external;

    function getrewardForBlock(uint256) external view returns (uint256);

    function getReward(uint256, uint256) external view returns (uint256);

    function poolInfo(uint256)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256
        );

    function userInfo(uint256, uint256)
        external
        view
        returns (uint256, uint256);

    function pendingeTaco(uint256, address) external view returns (uint256);

    function speedStake(
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    ) external payable returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function deposit(uint256, uint256) external;

    function setPool(
        uint256,
        address,
        uint256,
        uint256,
        uint256
    ) external;

    function setUser(
        uint256,
        address,
        uint256,
        uint256
    ) external;
}
