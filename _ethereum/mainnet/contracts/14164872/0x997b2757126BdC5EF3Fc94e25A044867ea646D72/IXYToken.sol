// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "IERC20.sol";

interface IXYToken is IERC20 {

    function mint(address account, uint256 amount) external;

    function burn(uint256 amount) external;
}
