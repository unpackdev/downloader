// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

interface IpalStTokenPool {
    function exchangeRateStored() external view returns (uint256);
}
