// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGasPriceConsumer {
    function getLatestGasPrice() external view returns (int);
}
