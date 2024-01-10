// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IInvestorV1Factory.sol";

import "./InvestorV1PoolDeployer.sol";
import "./InvestorV1Pool.sol";
import "./NoDelegateCall.sol";


contract InvestorV1Factory is IInvestorV1Factory, InvestorV1PoolDeployer, NoDelegateCall {

    address public override owner;
    address public override dao;
    address[] public override poolList;
    uint256 public override pools = 0;

    constructor() {
        owner = msg.sender;
        dao = msg.sender;
        emit OwnerChanged(address(0), msg.sender);
        emit DAOChanged(address(0), msg.sender);
    }

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
    ) external override noDelegateCall returns (address pool) {
        require(msg.sender == owner || msg.sender == dao, "InvestorV1Factory: not owner or dao");
        require(operator != address(0), "InvestorV1Factory: operator is zero address");
        require(capacity > 0, "InvestorV1Factory: maxCapacity is zero");
        require(startTime > block.timestamp, "InvestorV1Factory: startTime before now");
        require(startTime < endTime, "InvestorV1Factory: startTime after endTime");
        require(startTime < stageTime, "InvestorV1Factory: startTime after stageTime");
        require(stageTime < endTime, "InvestorV1Factory: stageTime after endTime");
        require(fee < 10000, "InvestorV1Factory: fee over 10000");
        require(oraclePrice > 0, "InvestorV1Factory: zero oraclePrice");
        pool = deploy(
            address(this),
            operator,
            poolList.length,
            name,
            capacity,
            oraclePrice,
            startTime,
            stageTime,
            endTime,
            fee,
            interestRate
        );
        poolList.push(pool);
        pools = pools + 1;

        emit PoolCreated(operator,name,poolList.length-1,capacity,startTime,stageTime,endTime,fee,interestRate,pool);
    }

    function setOwner(address _owner) external override {
        require(msg.sender == owner, "InvestorV1Factory: not owner");
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }

    function setDAO(address _dao) external override {
        require(msg.sender == dao, "InvestorV1Factory: not dao");
        emit DAOChanged(dao, _dao);
        dao = _dao;
    }
}