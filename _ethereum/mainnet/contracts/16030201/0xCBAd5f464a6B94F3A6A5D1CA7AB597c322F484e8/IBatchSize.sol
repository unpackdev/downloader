// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IBatchSize {
    function maxBatchSize() external returns (uint16);

    function updateBatchSize(uint16 batchSize_) external;
}
