// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ISimplePositionLeveragedLendingConnector {
    function increaseSimplePositionWithFlashLoan(
        address flashLoanToken,
        uint256 flashLoanAmount,
        address platform,
        address supplyToken,
        uint256 principalAmount,
        uint256 supplyAmount,
        address borrowToken,
        uint256 borrowAmount,
        bytes memory exchangeDataBeforePosition,
        bytes memory exchangeDataAfterPosition
    ) external;

    function decreaseSimplePositionWithFlashLoan(
        address flashLoanToken,
        uint256 flashLoanAmount,
        address platform,
        address redeemToken,
        uint256 redeemPrincipal,
        uint256 redeemAmount,
        address repayToken,
        uint256 repayAmount,
        bytes memory exchangeDataBeforePosition,
        bytes memory exchangeDataAfterPosition
    ) external;
}
