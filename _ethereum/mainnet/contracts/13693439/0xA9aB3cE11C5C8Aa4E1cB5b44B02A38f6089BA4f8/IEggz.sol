// contracts/IEGGZ.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";


interface IEggz is IERC20 {
    function burnFrom(address account, uint256 amount) external;
}