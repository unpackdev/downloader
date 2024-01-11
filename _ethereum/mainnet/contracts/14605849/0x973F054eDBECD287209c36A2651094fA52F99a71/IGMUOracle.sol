//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IGMUOracle {
    function getPrice() external view returns (uint256);

    function getDecimalPercision() external view returns (uint256);
}
