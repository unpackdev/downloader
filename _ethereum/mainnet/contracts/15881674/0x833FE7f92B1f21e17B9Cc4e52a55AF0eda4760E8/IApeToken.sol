// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IApeToken {
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

    function borrowBalanceStored(address account)
        external
        view
        returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function underlying() external view returns (address);
}
