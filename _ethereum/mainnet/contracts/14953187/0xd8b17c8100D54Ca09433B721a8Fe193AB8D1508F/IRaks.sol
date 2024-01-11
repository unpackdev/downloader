//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import "./IERC20Upgradeable.sol";

interface IRaks is IERC20Upgradeable {
    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}
