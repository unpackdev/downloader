//SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

pragma experimental ABIEncoderV2;

interface IEpochs {
    function getEpochLabels() external view returns (string[12] memory);

    function currentEpochs() external view returns (uint256[12] memory);

    function getEpochs(uint256 blockNumber)
        external
        pure
        returns (uint256[12] memory);
}