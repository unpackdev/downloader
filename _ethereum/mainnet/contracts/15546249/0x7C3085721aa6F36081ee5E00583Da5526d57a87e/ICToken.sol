// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ICToken {
    function exchangeRateStored() external view returns (uint256);

    function underlying() external view returns (address);
}
