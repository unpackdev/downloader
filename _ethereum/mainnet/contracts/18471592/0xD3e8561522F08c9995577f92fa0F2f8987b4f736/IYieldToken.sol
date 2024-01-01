// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20Metadata.sol";

interface IYieldToken is IERC20Metadata {
    function processFees(uint256 _interest, uint256 _price) external returns (uint256);

    function mint(address _to, uint256 _amount) external;
}
