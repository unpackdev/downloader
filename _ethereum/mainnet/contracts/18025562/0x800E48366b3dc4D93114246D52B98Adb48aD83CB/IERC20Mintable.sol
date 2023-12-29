// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC20Upgradeable.sol";

interface IERC20Mintable is IERC20Upgradeable {
    function mint(address _to, uint256 _value) external;
}
