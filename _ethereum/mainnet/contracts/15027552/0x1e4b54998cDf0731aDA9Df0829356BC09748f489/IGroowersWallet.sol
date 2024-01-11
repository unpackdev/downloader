// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./IERC20.sol";

interface IGroowersWallet {
    function getCount() external view returns(uint256 _id);
    function Stake(IERC20 token, uint256 amount, address from) external;
}
