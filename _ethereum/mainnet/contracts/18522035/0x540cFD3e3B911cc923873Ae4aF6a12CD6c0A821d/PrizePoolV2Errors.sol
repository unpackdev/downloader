// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

/**
 * @title Asymetrix Protocol V2 Errors library
 * @author Asymetrix Protocol Inc Team
 * @notice A library with Asymetrix Protocol V2 PrizePoolV2 errors.
 */
library PrizePoolV2Errors {
    error InvalidAddress();
    error InvalidTimestamp();
    error OnlyPrizeFlush();
    error OnlyTicket();
    error InvalidLiquidityCap();
    error InvalidBalanceCap();
    error NothingToLiquidate();
    error TooSmallLiquidationAmount();
    error AwardNotAvailable();
    error InvalidExternalToken();
    error InvalidArrayLength();
    error TicketAlreadySet();
    error InvalidLiquidationThreshold();
    error InvalidSlippageTolerance();
    error InvalidLidoAPR();
    error InvalidLiquidationAmount();
    error NotEnoughETH();
    error NotContract();
}
