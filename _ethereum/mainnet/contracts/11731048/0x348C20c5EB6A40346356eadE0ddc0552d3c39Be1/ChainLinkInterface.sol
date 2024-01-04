// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface ChainLinkInterface {
    function latestAnswer() external view returns (int256);

    function decimals() external view returns (uint256);
}
