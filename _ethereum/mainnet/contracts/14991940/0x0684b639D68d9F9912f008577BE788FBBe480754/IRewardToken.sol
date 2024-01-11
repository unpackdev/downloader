// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC20.sol";

interface IRewardToken is IERC20 {

    function mint(uint256 amount) external returns(bool);

}