// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./IERC20.sol";


interface IWrapper {
    function wrap(IERC20 token) external view returns (IERC20 wrappedToken, uint256 rate);
}
