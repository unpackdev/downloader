// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IInvestorV1Factory {
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    event PoolCreated(
        address operator,
        string name,
        uint256 maxCapacity,
        uint256 minCapacity,
        uint256 startTime,
        uint256 stageTime,
        uint256 endTime,
        uint24 fee,
        uint24 interestRate,
        address pool
    );

    function owner() external view returns (address); 

    function pools() external view returns (uint256);

    function poolList(uint256 index) external view returns (address);

    function getPool(
        address operator,
        string memory name,
        uint256 startTime
    ) external view returns (address pool);

    function createPool(
        address operator,
        string memory name,
        uint256 maxCapacity,
        uint256 minCapacity,
        uint256 oraclePrice,
        uint256 startTime,
        uint256 stageTime,
        uint256 endTime,
        uint24 fee,
        uint24 interestRate
    ) external returns (address pool);

    function setOwner(address _owner) external;
}