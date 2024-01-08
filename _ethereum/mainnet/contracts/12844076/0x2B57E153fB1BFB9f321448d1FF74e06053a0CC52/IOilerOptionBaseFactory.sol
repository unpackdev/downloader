// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface IOilerOptionBaseFactory {
    function optionLogicImplementation() external view returns (address);

    function isClone(address _query) external view returns (bool);
}
