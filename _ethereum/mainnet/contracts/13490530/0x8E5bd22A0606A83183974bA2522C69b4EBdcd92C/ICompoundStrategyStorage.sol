// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface ICompoundStrategyStorage {
    function comptroller() external view returns (address);
}
