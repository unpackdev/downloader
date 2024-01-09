// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IERC20.sol";
import "./AccessControl.sol";

interface IPGLD is IERC20 {
    function mint(address account, uint256 amount) external;
}
