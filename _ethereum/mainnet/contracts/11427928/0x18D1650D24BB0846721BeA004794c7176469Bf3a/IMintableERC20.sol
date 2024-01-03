//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

import "./IERC20.sol";

interface IMintableERC20 is IERC20 {
    function mint(address account, uint256 amount) external;
}
