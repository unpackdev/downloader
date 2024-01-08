// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;
pragma experimental ABIEncoderV2;

import "./IEPoolHelper.sol";
import "./IEPool.sol";

import "./EPoolLibrary.sol";

contract EPoolHelper is IEPoolHelper {

    function currentRatio(IEPool ePool, address eToken) external view override returns(uint256) {
        return EPoolLibrary.currentRatio(ePool.getTranche(eToken), ePool.getRate(), ePool.sFactorA(), ePool.sFactorB());
    }

    function delta(
        IEPool ePool
    ) external view override returns (uint256 deltaA, uint256 deltaB, uint256 rChange, uint256 rDiv) {
        return EPoolLibrary.delta(ePool.getTranches(), ePool.getRate(), ePool.sFactorA(), ePool.sFactorB());
    }

    function eTokenForTokenATokenB(
        IEPool ePool,
        address eToken,
        uint256 amountA,
        uint256 amountB
    ) external view override returns (uint256) {
        return EPoolLibrary.eTokenForTokenATokenB(
            ePool.getTranche(eToken), amountA, amountB, ePool.getRate(), ePool.sFactorA(), ePool.sFactorB()
        );
    }

    function tokenATokenBForEToken(
        IEPool ePool,
        address eToken,
        uint256 amount
    ) external view override returns (uint256 amountA, uint256 amountB) {
        return EPoolLibrary.tokenATokenBForEToken(
            ePool.getTranche(eToken), amount, ePool.getRate(), ePool.sFactorA(), ePool.sFactorB()
        );
    }

    function tokenATokenBForTokenA(
        IEPool ePool,
        address eToken,
        uint256 _totalA
    ) external view override returns (uint256 amountA, uint256 amountB) {
        uint256 sFactorA = ePool.sFactorA();
        uint256 sFactorB = ePool.sFactorB();
        uint256 rate = ePool.getRate();
        return EPoolLibrary.tokenATokenBForTokenA(
            _totalA,
            EPoolLibrary.currentRatio(ePool.getTranche(eToken), rate, sFactorA, sFactorB),
            rate,
            sFactorA,
            sFactorB
        );
    }

    function tokenATokenBForTokenB(
        IEPool ePool,
        address eToken,
        uint256 _totalB
    ) external view override returns (uint256 amountA, uint256 amountB) {
        uint256 sFactorA = ePool.sFactorA();
        uint256 sFactorB = ePool.sFactorB();
        uint256 rate = ePool.getRate();
        return EPoolLibrary.tokenATokenBForTokenB(
            _totalB,
            EPoolLibrary.currentRatio(ePool.getTranche(eToken), rate, sFactorA, sFactorB),
            rate,
            sFactorA,
            sFactorB
        );
    }

    function tokenBForTokenA(
        IEPool ePool,
        address eToken,
        uint256 amountA
    ) external view override returns (uint256 amountB) {
        uint256 sFactorA = ePool.sFactorA();
        uint256 sFactorB = ePool.sFactorB();
        uint256 rate = ePool.getRate();
        return EPoolLibrary.tokenBForTokenA(
            amountA,
            EPoolLibrary.currentRatio(ePool.getTranche(eToken), rate, sFactorA, sFactorB),
            rate,
            sFactorA,
            sFactorB
        );
    }

    function tokenAForTokenB(
        IEPool ePool,
        address eToken,
        uint256 amountB
    ) external view override returns (uint256 amountA) {
        uint256 sFactorA = ePool.sFactorA();
        uint256 sFactorB = ePool.sFactorB();
        uint256 rate = ePool.getRate();
        return EPoolLibrary.tokenAForTokenB(
            amountB,
            EPoolLibrary.currentRatio(ePool.getTranche(eToken), rate, sFactorA, sFactorB),
            rate,
            sFactorA,
            sFactorB
        );
    }

    function totalA(
        IEPool ePool,
        uint256 amountA,
        uint256 amountB
    ) external view override returns (uint256) {
        return EPoolLibrary.totalA(amountA, amountB, ePool.getRate(), ePool.sFactorA(), ePool.sFactorB());
    }

    function totalB(
        IEPool ePool,
        uint256 amountA,
        uint256 amountB
    ) external view override returns (uint256) {
        return EPoolLibrary.totalB(amountA, amountB, ePool.getRate(), ePool.sFactorA(), ePool.sFactorB());
    }

    function feeAFeeBForEToken(
        IEPool ePool,
        address eToken,
        uint256 amount
    ) external view override returns (uint256 feeA, uint256 feeB) {
        (uint256 amountA, uint256 amountB) = EPoolLibrary.tokenATokenBForEToken(
            ePool.getTranche(eToken), amount, ePool.getRate(), ePool.sFactorA(), ePool.sFactorB()
        );
        return EPoolLibrary.feeAFeeBForTokenATokenB(amountA, amountB, ePool.feeRate());
    }
}
