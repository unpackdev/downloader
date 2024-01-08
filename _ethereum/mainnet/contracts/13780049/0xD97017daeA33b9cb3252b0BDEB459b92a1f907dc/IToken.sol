// contracts/IToken.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";


interface IToken is IERC20 {
    function burnFrom(address account, uint256 amount) external;
}