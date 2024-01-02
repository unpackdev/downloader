// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

/**
 * @title Asymetrix Protocol V2 Errors library
 * @author Asymetrix Protocol Inc Team
 * @notice A library with Asymetrix Protocol V2 ESASX errors.
 */
library ESASXErrors {
    error InvalidAddress();
    error WrongVestingPeriod();
    error WrongVestingAmount();
    error NotExistingVP();
    error InvalidLength();
    error InvalidRange();
    error OutOfBounds();
    error NothingToRelease();
    error NotEnoughUnlockedASX();
    error NotEnoughUnlockedESASX();
    error NotEnoughASXWithDiscount();
    error NotEnoughETH();
    error WrongETHAmount();
    error InvalidEsASXAmount();
    error InvalidSlippageTolerance();
    error NotContract();
    error WrongBalancerPoolTokensNumber();
    error NonTransferable();
    error InvalidSignature();
    error MevProtection();
}
