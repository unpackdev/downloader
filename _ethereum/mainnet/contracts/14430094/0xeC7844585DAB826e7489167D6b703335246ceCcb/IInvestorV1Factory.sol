// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IInvestorV1Factory {
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event DAOChanged(address indexed oldDAO, address indexed newDAO);

    event PoolCreated(
        address operator,
        string name,
        uint256 fundId,
        uint256 capacity,
        uint256 startTime,
        uint256 stageTime,
        uint256 endTime,
        uint24 fee,
        uint24 interestRate,
        address pool
    );

    function owner() external view returns (address); 
    function dao() external view returns (address); 

    function pools() external view returns (uint256);

    function poolList(uint256 index) external view returns (address);

    function createPool(
        address operator,
        string memory name,
        uint256 capacity,
        uint256 oraclePrice,
        uint256 startTime,
        uint256 stageTime,
        uint256 endTime,
        uint24 fee,
        uint24 interestRate
    ) external returns (address pool);

    function setOwner(address _owner) external;
    function setDAO(address _dao) external;
}