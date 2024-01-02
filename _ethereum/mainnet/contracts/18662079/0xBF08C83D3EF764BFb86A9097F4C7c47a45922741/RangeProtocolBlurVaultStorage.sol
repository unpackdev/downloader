// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./DataTypes.sol";
import "./IRangeProtocolBlurVault.sol";
import "./Structs.sol";
import "./IBlurPool.sol";
import "./IBlend.sol";

abstract contract RangeProtocolBlurVaultStorage is IRangeProtocolBlurVault {
    DataTypes.State internal state;

    function blurPool() external view override returns (IBlurPool) {
        return state.blurPool;
    }

    function blend() external view override returns (IBlend) {
        return state.blend;
    }

    function getLiensByIndex(
        uint256 from,
        uint256 to
    ) external view override returns (DataTypes.LienData[] memory liensData) {
        liensData = new DataTypes.LienData[](to - from);
        for (uint256 i = from; i < to; i++) {
            liensData[i - from] = state.liens[i];
        }
    }

    function liensCount() external view override returns (uint256) {
        return state.liens.length;
    }

    function managerFee() external view returns (uint256) {
        return state.managerFee;
    }
}
