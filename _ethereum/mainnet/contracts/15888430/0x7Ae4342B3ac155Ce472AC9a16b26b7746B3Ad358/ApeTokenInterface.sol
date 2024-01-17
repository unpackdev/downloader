// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ApeTokenInterface {
    function underlying() external view returns (address);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function mint(address minter, uint256 mintAmount)
        external
        returns (uint256);

    function redeem(
        address payable redeemer,
        uint256 redeemTokens,
        uint256 redeemAmount
    ) external returns (uint256);

    function borrow(address payable borrower, uint256 borrowAmount)
        external
        returns (uint256);

    function repayBorrow(address borrower, uint256 repayAmount)
        external
        returns (uint256);

    function mintNative(address minter) external payable returns (uint256);

    function redeemNative(
        address payable redeemer,
        uint256 redeemTokens,
        uint256 redeemAmount
    ) external returns (uint256);

    function borrowNative(address payable borrower, uint256 borrowAmount)
        external
        returns (uint256);

    function repayBorrowNative(address borrower)
        external
        payable
        returns (uint256);
}
