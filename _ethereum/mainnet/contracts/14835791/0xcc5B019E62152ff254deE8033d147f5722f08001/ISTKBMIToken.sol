// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "./IERC20Upgradeable.sol";

interface ISTKBMIToken is IERC20Upgradeable {
    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}
