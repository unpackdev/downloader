// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IWithIncentivesPool {
    event IncentivesPoolSetTransferred(address indexed previousIncentivesPool, address indexed newIncentivesPool);
    function incentivesPool() external view returns (address);
    function setIncentivesPool(address newIncentivesPool) external;
}
