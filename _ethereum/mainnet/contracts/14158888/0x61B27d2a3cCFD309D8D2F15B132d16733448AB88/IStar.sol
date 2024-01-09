// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IStar {
    /* ================ EVENTS ================ */

    event Donate(address indexed sender, uint256 value, uint256 reward);

    /* ================ VIEW FUNCTIONS ================ */

    /* ================ TRANSACTION FUNCTIONS ================ */

    function donate(uint256 answer) external payable;

    /* ================ ADMIN FUNCTIONS ================ */

    function get(address receiver) external;

    function transferAnyERC20Token(
        address token,
        address to,
        uint256 amount
    ) external;
}
