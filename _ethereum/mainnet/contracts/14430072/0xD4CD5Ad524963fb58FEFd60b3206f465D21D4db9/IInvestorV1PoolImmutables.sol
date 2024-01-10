// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IInvestorV1PoolImmutables {
    function factory() external view returns (address);
    function operator() external view returns (address);
    function name() external view returns (string memory);
    function capacity() external view returns (uint256);
    function fundId() external view returns (uint256);
    function startTime() external view returns (uint256);
    function stageTime() external view returns (uint256);
    function endTime() external view returns (uint256);
    function fee() external view returns (uint24);
    function interestRate() external view returns (uint24);
}