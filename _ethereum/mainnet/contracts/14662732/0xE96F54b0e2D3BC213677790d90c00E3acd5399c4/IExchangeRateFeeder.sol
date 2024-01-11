//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IExchangeRateFeeder {
    function exchangeRateOf(address _token, bool _simulate) external view returns (uint256);
    function update(address _token) external;
}