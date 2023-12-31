//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./IERC20.sol";

interface ITreasury {
    event Deposit(
        address indexed _depositor,
        IERC20 indexed _token,
        uint256 _value
    );
    event DepositableToken(IERC20 indexed _token, address indexed _priceFreed);
    event TokenRemoved(IERC20 indexed _token);
}
