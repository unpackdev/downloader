// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;
import "./IERC20.sol";

interface ISonic is IERC20 {
    function owner() external view returns (address);

    function accountBurn(address account, uint256 amount) external;

    function accountReward(address account, uint256 amount) external;

    function liquidityReward(uint256 amount) external;

    function mint(address account, uint256 amount) external;
}