// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";

interface IROOLAH is IERC20Upgradeable {
    function mint(address recipient, uint256 amount) external;
    function burn(uint256 amount) external;
}
