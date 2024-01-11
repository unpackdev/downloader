//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "./IERC20.sol";

interface IGroToken is IERC20 {
    function pricePerShare() external view returns (uint256);

    function getShareAssets(uint256) external view returns (uint256);
}