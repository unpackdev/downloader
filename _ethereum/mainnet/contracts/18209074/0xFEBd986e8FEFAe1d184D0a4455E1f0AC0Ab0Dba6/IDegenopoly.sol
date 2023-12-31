// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "./IERC20Upgradeable.sol";

interface IDegenopoly is IERC20Upgradeable {
    function mint(address _to, uint256 _amount) external;
}
