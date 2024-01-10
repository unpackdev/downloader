// SPDX-License-Identifier: MIT

import "./IERC20.sol";

pragma solidity 0.8.11;

interface IERC20Mintable is IERC20 {
    function mint(address, uint256) external;

    function burn(address, uint256) external;
}
