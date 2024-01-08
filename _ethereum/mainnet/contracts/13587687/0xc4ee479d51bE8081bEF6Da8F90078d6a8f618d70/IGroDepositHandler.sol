//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

interface IGroDepositHandler {

    function depositGvt(
        uint256[3] calldata inAmounts,
        uint256 minAmount,
        address referral
    ) external;

    function depositPwrd(
        uint256[3] calldata inAmounts,
        uint256 minAmount,
        address referral
    ) external;
}