// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

interface ITreasury {
    function onSellFeePaid(address from, uint256 amount) external;
    function onBuyFeePaid(address from, uint256 amount) external;
}
