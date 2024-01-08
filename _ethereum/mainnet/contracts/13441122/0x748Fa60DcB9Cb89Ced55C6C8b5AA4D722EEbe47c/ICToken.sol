// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICToken {
    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function underlying() external view returns (address);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function comptroller() external view returns (address);
}
