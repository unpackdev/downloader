// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

interface IPool {
    function getPoolId() external view returns (bytes32);

    function getNormalizedWeights() external view returns (uint256[] memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _user) external view returns (uint256);
}
