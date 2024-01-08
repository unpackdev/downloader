// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

interface IRandom {

    function drawStatelessIndex(uint256 _length) view external returns (uint256);

    function drawIndex(uint256 _length) external returns (uint256);

    function drawWeightedIndex(uint16[] calldata _probabilities) external returns (uint256);

    function drawColor() external view returns (string memory);

}