// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.21;

interface IOracle {
    function aprAfterDebtChange(
        address _asset,
        int256 _delta
    ) external view returns (uint256);

    function getUtilizationInfo(
        address _strategy
    ) external view returns (uint256, uint256);
}
