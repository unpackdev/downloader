// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IMomocoToken is IERC20 {
    function mint(address to, uint value) external returns (bool);
    function take() external view returns (uint);
    function funds(address _user) external view returns (uint);
}
