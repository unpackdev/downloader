// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import "./IERC20.sol";

interface IMintableERC20 is IERC20 {
    function mint(address to, uint256 value) external returns (bool);

    function burn(address from, uint256 value) external returns (bool);
}
