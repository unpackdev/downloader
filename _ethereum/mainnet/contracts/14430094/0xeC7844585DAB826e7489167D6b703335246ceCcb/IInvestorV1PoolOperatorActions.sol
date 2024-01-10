// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IInvestorV1PoolOperatorActions {
    function setOraclePrice(uint256 _oraclePrice) external returns (bool);
    function setColletralHash(string memory _newHash) external returns (bool);
    function setColletralLink(string memory _newLink) external returns (bool);
    function setPoolDetailLink(string memory _newLink) external returns (bool);
    function rescue(address target) external returns (bool);
    function pullDeposit() external returns (bool);
    function liquidate() external returns (bool);
    function openPool() external returns (bool);
    function closePool() external returns (bool);
    function revertPool() external returns (bool);
}