// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./OpynVault.sol";

interface IMarginCalculator {
    function getExcessCollateral(
        MarginVault.Vault calldata _vault,
        uint256 _vaultType
    ) external view returns (uint256 netValue, bool isExcess);
}
