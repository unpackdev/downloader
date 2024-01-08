// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./IERC20.sol";

interface IRena is IERC20 {
        function distributeFees() external;
        function treasury() external returns (address payable);
        function uniRouter() external returns (address);
        function approve(address, uint256) external override returns(bool);
}