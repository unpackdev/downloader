// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IERC20.sol";

interface IDroppingNowToken is IERC20 {
    function addMintable(address[] memory to, uint256[] memory amounts) external;

    function addReward() external payable;

    function claimReward() external;

    function claimTokens() external;

    function rewardBalanceOf(address owner) external view returns (uint256);

    function mintableBalanceOf(address owner) external view returns (uint256);
}