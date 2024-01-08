// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./IERC20.sol";

// enhanced ERC20 interface with decimals
interface IERC20Decimals is IERC20 {

    function decimals() external view returns (uint8);
}
