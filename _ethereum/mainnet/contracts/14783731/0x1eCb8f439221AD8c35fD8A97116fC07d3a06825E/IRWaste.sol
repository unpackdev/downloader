//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import "./IERC20.sol";

interface IRWaste is IERC20 {
    function burn(address user, uint256 amount) external;
    function claimReward() external;
}