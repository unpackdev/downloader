// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./IERC20.sol";

interface IxToken is IERC20 {
    function previewNonDistributedYield() external view returns(uint256);

    function getNonDistributedYield() external returns(uint256);

    function stake(uint256 amount) external;

    function unstake(uint256 amount) external;

    function xBasketTransfer(address _from, uint256 amount) external;

    function Staked(address)
        external
        view
        returns (uint256 amount, uint256 startTime); // Not

    function availableToClaim(address account) external view returns (uint256);

    function claim() external;
}