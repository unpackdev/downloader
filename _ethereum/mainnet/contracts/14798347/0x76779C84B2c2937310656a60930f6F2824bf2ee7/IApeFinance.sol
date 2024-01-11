// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

interface IApeFinance {

    function balanceOf(address account) external view returns (uint256);

    function borrow(address payable borrower, uint256 borrowAmount) external returns (uint256);

    function underlying() external view returns (address);

    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        address cTokenCollateral
    ) external returns (uint256);

    function redeem(
        address payable redeemer,
        uint256 redeemTokens,
        uint256 redeemAmount
    ) external returns (uint256);

    function repayBorrow(address borrower, uint256 repayAmount)
        external
        returns (uint256);
}
