// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ProtocolAaveV2Interface {
    function depositToken(address token, uint256 amt)
        external
        payable
        returns (uint256 _amt);

    function withdrawToken(address token, uint256 amt)
        external
        payable
        returns (uint256 _amt);

    function borrowToken(
        address token,
        uint256 amt,
        uint256 rateMode
    ) external payable returns (uint256 _amt);

    function paybackToken(
        address token,
        uint256 amt,
        uint256 rateMode
    ) external payable returns (uint256 _amt);

    function enableTokenCollateral(address[] calldata tokens) external payable;

    function swapTokenBorrowRateMode(address token, uint256 rateMode)
        external
        payable;

    function getPaybackBalance(address token, uint256 rateMode)
        external
        view
        returns (uint256);

    function getCollateralBalance(address token)
        external
        view
        returns (uint256 bal);
}
