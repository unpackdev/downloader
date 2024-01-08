// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IInvestorV1PoolDeployer.sol";

import "./InvestorV1Pool.sol";

contract InvestorV1PoolDeployer is IInvestorV1PoolDeployer {
    struct Parameter1 {
        address factory;
        address operator;
        string  name;
        uint256 maxCapacity;
        uint256 minCapacity;
    }

    struct Parameter2 {
        uint256 oraclePrice;
        uint256 startTime;
        uint256 stageTime;
        uint256 endTime;
        uint24  fee;
        uint24  interestRate;
    }

    Parameter1 public override parameter1;
    Parameter2 public override parameter2;

    function deploy(
        address factory,
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
    ) internal returns (address pool) {
        parameter1 = Parameter1({
            factory: factory, 
            operator: operator, 
            name: name, 
            maxCapacity: maxCapacity, 
            minCapacity: minCapacity
        });
        parameter2 = Parameter2({
            oraclePrice: oraclePrice,
            startTime: startTime,
            stageTime: stageTime,
            endTime: endTime,
            fee: fee,
            interestRate: interestRate
        });
        pool = address(new InvestorV1Pool{salt: keccak256(abi.encode(operator, name, startTime))}());
        delete parameter1;
        delete parameter2;
    }
}