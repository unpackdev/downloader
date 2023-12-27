// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "IERC20Mint.sol";

interface IERC20Burn is IERC20Mint {
    function burn(address _burnFor, uint256 _amount) external;
}