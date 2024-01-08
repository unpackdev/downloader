// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";


interface IFeeCollector {
    function updateReward(address receiver, uint256 amount) external;
    function updateRewardNonLP(IERC20 erc20, address receiver, uint256 amount) external;
    function updateRewards(address[] calldata receivers, uint256[] calldata amounts) external;
}
