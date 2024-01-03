// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface ICLiquidator {
    
    function liquidateBorrow(
        address vToken,
        address borrower,
        uint256 repayAmount,
        address vTokenCollateral
    ) external payable;

}