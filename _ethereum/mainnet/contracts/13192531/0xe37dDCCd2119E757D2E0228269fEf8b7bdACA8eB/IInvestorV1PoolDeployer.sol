// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IInvestorV1PoolDeployer {
    
    function parameter1()
        external
        view
        returns (
            address factory,
            address operator,
            string memory name,
            uint256 maxCapacity,
            uint256 minCapacity
        );

    function parameter2()
        external
        view
        returns (
            uint256 oraclePrice,
            uint256 startTime,
            uint256 stageTime,
            uint256 endTime,
            uint24 fee,
            uint24 interestRate
        );
}