// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IERC20.sol";

interface ITickets is IERC20 {
    function print(address _account, uint256 _amount) external;

    function redeem(address _account, uint256 _amount) external;
}
