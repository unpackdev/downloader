// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IFundProxy {
    function implementation() external view returns (address);
}
