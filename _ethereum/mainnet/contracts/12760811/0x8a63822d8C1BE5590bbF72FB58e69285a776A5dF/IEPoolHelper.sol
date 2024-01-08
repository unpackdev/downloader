// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;
pragma experimental ABIEncoderV2;

import "./IEPool.sol";

interface IEPoolHelper {

    function currentRatio(IEPool ePool, address eToken) external view returns(uint256);

    function delta(IEPool ePool) external view returns (uint256 deltaA, uint256 deltaB, uint256 rChange, uint256 rDiv);

    function eTokenForTokenATokenB(
        IEPool ePool,
        address eToken,
        uint256 amountA,
        uint256 amountB
    ) external view returns (uint256);

    function tokenATokenBForEToken(
        IEPool ePool,
        address eToken,
        uint256 amount
    ) external view returns (uint256 amountA, uint256 amountB);

    function tokenATokenBForTokenA(
        IEPool ePool,
        address eToken,
        uint256 _totalA
    ) external view returns (uint256 amountA, uint256 amountB);

    function tokenATokenBForTokenB(
        IEPool ePool,
        address eToken,
        uint256 _totalB
    ) external view returns (uint256 amountA, uint256 amountB);

    function tokenBForTokenA(
        IEPool ePool,
        address eToken,
        uint256 amountA
    ) external view returns (uint256 amountB);

    function tokenAForTokenB(
        IEPool ePool,
        address eToken,
        uint256 amountB
    ) external view returns (uint256 amountA);

    function totalA(
        IEPool ePool,
        uint256 amountA,
        uint256 amountB
    ) external view returns (uint256);

    function totalB(
        IEPool ePool,
        uint256 amountA,
        uint256 amountB
    ) external view returns (uint256);

    function feeAFeeBForEToken(
        IEPool ePool,
        address eToken,
        uint256 amount
    ) external view returns (uint256 feeA, uint256 feeB);
}
