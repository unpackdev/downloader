// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";

interface IToken is IERC20Upgradeable {
    function decimals() external view returns (uint8);
}
