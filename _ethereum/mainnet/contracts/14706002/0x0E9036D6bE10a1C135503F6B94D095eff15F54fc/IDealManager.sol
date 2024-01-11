// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface IDealManager {
    function createDaoDepositManager(address _dao) external;

    function hasDaoDepositManager(address _dao) external view returns (bool);

    function getDaoDepositManager(address _dao) external view returns (address);

    function owner() external view returns (address);

    function weth() external view returns (address);

    function isModule(address who) external view returns (bool);
}
