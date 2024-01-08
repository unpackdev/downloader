//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20Metadata.sol";

interface IConvexMinter is IERC20Metadata {
    function totalCliffs() external view returns (uint256);

    function reductionPerCliff() external view returns (uint256);
}
