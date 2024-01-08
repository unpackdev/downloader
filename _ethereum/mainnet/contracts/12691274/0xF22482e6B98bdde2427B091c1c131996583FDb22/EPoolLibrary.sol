// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;
pragma experimental ABIEncoderV2;

import "./SafeERC20.sol";
import "./IERC20.sol";

import "./IETokenFactory.sol";
import "./IEToken.sol";
import "./IEPool.sol";
import "./TokenUtils.sol";
import "./Math.sol";

library EPoolLibrary {
    using TokenUtils for IERC20;

    uint256 internal constant sFactorI = 1e18; // internal scaling factor (18 decimals)

    /**
     * @notice Returns the target ratio if reserveA and reserveB are 0 (for initial deposit)
     * currentRatio := (reserveA denominated in tokenB / reserveB denominated in tokenB) with decI decimals
     */
    function currentRatio(
        IEPool.Tranche memory t,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal pure returns(uint256) {
        if (t.reserveA == 0 || t.reserveB == 0) {
            if (t.reserveA == 0 && t.reserveB == 0) return t.targetRatio;
            if (t.reserveA == 0) return 0;
            if (t.reserveB == 0) return type(uint256).max;
        }
        return ((t.reserveA * rate / sFactorA) * sFactorI) / (t.reserveB * sFactorI / sFactorB);
    }

    /**
     * @notice Returns the deviation of reserveA and reserveB from target ratio
     * currentRatio > targetRatio: release TokenA liquidity and add TokenB liquidity
     * currentRatio < targetRatio: add TokenA liquidity and release TokenB liquidity
     * deltaA := abs(t.reserveA, (t.reserveB / rate * t.targetRatio)) / (1 + t.targetRatio)
     * deltaB := deltaA * rate
     */
    function trancheDelta(
        IEPool.Tranche memory t,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal pure returns (uint256 deltaA, uint256 deltaB, uint256 rChange) {
        rChange = (currentRatio(t, rate, sFactorA, sFactorB) < t.targetRatio) ? 1 : 0;
        deltaA = (
            Math.abs(t.reserveA, tokenAForTokenB(t.reserveB, t.targetRatio, rate, sFactorA, sFactorB)) * sFactorA
        ) / (sFactorA + (t.targetRatio * sFactorA / sFactorI));
        // (convert to TokenB precision first to avoid altering deltaA)
        deltaB = ((deltaA * sFactorB / sFactorA) * rate) / sFactorI;
    }

    /**
     * @notice Returns the sum of the tranches reserve deltas
     */
    function delta(
        IEPool.Tranche[] memory ts,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal pure returns (uint256 deltaA, uint256 deltaB, uint256 rChange, uint256 rDiv) {
        uint256 totalReserveA;
        int256 totalDeltaA;
        int256 totalDeltaB;
        for (uint256 i = 0; i < ts.length; i++) {
            totalReserveA += ts[i].reserveA;
            (uint256 _deltaA, uint256 _deltaB, uint256 _rChange) = trancheDelta(
                ts[i], rate, sFactorA, sFactorB
            );
            (totalDeltaA, totalDeltaB) = (_rChange == 0)
                ? (totalDeltaA - int256(_deltaA), totalDeltaB + int256(_deltaB))
                : (totalDeltaA + int256(_deltaA), totalDeltaB - int256(_deltaB));
        }
        if (totalDeltaA > 0)  {
            (deltaA, deltaB, rChange) = (uint256(totalDeltaA), uint256(-totalDeltaB), 1);
        } else {
            (deltaA, deltaB, rChange) = (uint256(-totalDeltaA), uint256(totalDeltaB), 0);
        }
        rDiv = (totalReserveA == 0) ? 0 : deltaA * EPoolLibrary.sFactorI / totalReserveA;
    }

    /**
     * @notice how much EToken can be issued, redeemed for amountA and amountB
     * initial issuance / last redemption: sqrt(amountA * amountB)
     * subsequent issuances / non nullifying redemptions: claim on reserve * EToken total supply
     */
    function eTokenForTokenATokenB(
        IEPool.Tranche memory t,
        uint256 amountA,
        uint256 amountB,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal view returns (uint256) {
        uint256 amountsA = totalA(amountA, amountB, rate, sFactorA, sFactorB);
        if (t.reserveA + t.reserveB == 0) {
            return (Math.sqrt((amountsA * t.sFactorE / sFactorA) * t.sFactorE));
        }
        uint256 reservesA = totalA(t.reserveA, t.reserveB, rate, sFactorA, sFactorB);
        uint256 share = ((amountsA * t.sFactorE / sFactorA) * t.sFactorE) / (reservesA * t.sFactorE / sFactorA);
        return share * t.eToken.totalSupply() / t.sFactorE;
    }

    /**
     * @notice Given an amount of EToken, how much TokenA and TokenB have to be deposited, withdrawn for it
     * initial issuance / last redemption: sqrt(amountA * amountB) -> such that the inverse := EToken amount ** 2
     * subsequent issuances / non nullifying redemptions: claim on EToken supply * reserveA/B
     */
    function tokenATokenBForEToken(
        IEPool.Tranche memory t,
        uint256 amount,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal view returns (uint256 amountA, uint256 amountB) {
        if (t.reserveA + t.reserveB == 0) {
            uint256 amountsA = amount * sFactorA / t.sFactorE;
            (amountA, amountB) = tokenATokenBForTokenA(
                amountsA * amountsA / sFactorA , t.targetRatio, rate, sFactorA, sFactorB
            );
        } else {
            uint256 eTokenTotalSupply = t.eToken.totalSupply();
            if (eTokenTotalSupply == 0) return(0, 0);
            uint256 share = amount * t.sFactorE / eTokenTotalSupply;
            amountA = share * t.reserveA / t.sFactorE;
            amountB = share * t.reserveB / t.sFactorE;
        }
    }

    /**
     * @notice Given amountB, which amountA is required such that amountB / amountA is equal to the ratio
     * amountA := amountBInTokenA * ratio
     */
    function tokenAForTokenB(
        uint256 amountB,
        uint256 ratio,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal pure returns(uint256) {
        return (((amountB * sFactorI / sFactorB) * ratio) / rate) * sFactorA / sFactorI;
    }

    /**
     * @notice Given amountA, which amountB is required such that amountB / amountA is equal to the ratio
     * amountB := amountAInTokenB / ratio
     */
    function tokenBForTokenA(
        uint256 amountA,
        uint256 ratio,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal pure returns(uint256) {
        return (((amountA * sFactorI / sFactorA) * rate) / ratio) * sFactorB / sFactorI;
    }

    /**
     * @notice Given an amount of TokenA, how can it be split up proportionally into amountA and amountB
     * according to the ratio
     * amountA := total - (total / (1 + ratio)) == (total * ratio) / (1 + ratio)
     * amountB := (total / (1 + ratio)) * rate
     */
    function tokenATokenBForTokenA(
        uint256 _totalA,
        uint256 ratio,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal pure returns (uint256 amountA, uint256 amountB) {
        amountA = _totalA - (_totalA * sFactorI / (sFactorI + ratio));
        amountB = (((_totalA * sFactorI / sFactorA) * rate) / (sFactorI + ratio)) * sFactorB / sFactorI;
    }

    /**
     * @notice Given an amount of TokenB, how can it be split up proportionally into amountA and amountB
     * according to the ratio
     * amountA := (total * ratio) / (rate * (1 + ratio))
     * amountB := total / (1 + ratio)
     */
    function tokenATokenBForTokenB(
        uint256 _totalB,
        uint256 ratio,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal pure returns (uint256 amountA, uint256 amountB) {
        amountA = ((((_totalB * sFactorI / sFactorB) * ratio) / (sFactorI + ratio)) * sFactorA) / rate;
        amountB = (_totalB * sFactorI) / (sFactorI + ratio);
    }

    /**
     * @notice Return the total value of amountA and amountB denominated in TokenA
     * totalA := amountA + (amountB / rate)
     */
    function totalA(
        uint256 amountA,
        uint256 amountB,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal pure returns (uint256 _totalA) {
        return amountA + ((((amountB * sFactorI / sFactorB) * sFactorI) / rate) * sFactorA) / sFactorI;
    }

    /**
     * @notice Return the total value of amountA and amountB denominated in TokenB
     * totalB := amountB + (amountA * rate)
     */
    function totalB(
        uint256 amountA,
        uint256 amountB,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal pure returns (uint256 _totalB) {
        return amountB + ((amountA * rate / sFactorA) * sFactorB) / sFactorI;
    }

    /**
     * @notice Return the withdrawal fee for a given amount of TokenA and TokenB
     * feeA := amountA * feeRate
     * feeB := amountB * feeRate
     */
    function feeAFeeBForTokenATokenB(
        uint256 amountA,
        uint256 amountB,
        uint256 feeRate
    ) internal pure returns (uint256 feeA, uint256 feeB) {
        feeA = amountA * feeRate / EPoolLibrary.sFactorI;
        feeB = amountB * feeRate / EPoolLibrary.sFactorI;
    }
}
