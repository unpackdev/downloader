// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";

interface IFortunaToken is IERC20 {
    function mint(address recipient, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}
