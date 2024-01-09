// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "IERC20.sol";
import "draft-IERC20Permit.sol";


interface IToken is IERC20, IERC20Permit {
    function burnFrom(address account, uint256 amount) external;
}