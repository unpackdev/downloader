// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IChainlinkPriceConsumer {

    function getLatestPrice() external view returns (int);

    function getDecimals() external view returns (uint8);
}
