// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "./IERC20.sol";

interface ISteth is IERC20 {
    event Submitted(address sender, uint256 amount, address referral);

    function submit(address) external payable returns (uint256);
}
