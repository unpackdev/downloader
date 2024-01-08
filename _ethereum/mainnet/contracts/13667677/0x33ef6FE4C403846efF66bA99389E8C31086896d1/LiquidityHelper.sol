// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma abicoder v2;

import "./SafeMath.sol";

import "./ICHIVault.sol";
import "./ICHIManager.sol";

library LiquidityHelper {
    function removeVaultAllLiquidityFromPosition(ICHIVault vault) internal {
        for (uint256 i = 0; i < vault.getRangeCount(); i++) {
            vault.removeAllLiquidityFromPosition(i);
        }
    }

    function addAllLiquidityToPosition(
        ICHIVault vault,
        uint256[] calldata ranges,
        uint256[] calldata amount0Totals,
        uint256[] calldata amount1Totals
    ) internal {
        require(
            ranges.length == amount0Totals.length &&
                amount0Totals.length == amount1Totals.length,
            "len"
        );
        for (uint256 i; i < ranges.length; i++) {
            vault.addLiquidityToPosition(
                ranges[i],
                amount0Totals[i],
                amount1Totals[i]
            );
        }
    }
}
