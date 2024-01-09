// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./IERC20.sol";

interface IERC20Mintable is IERC20 {

    function mint(address to, uint256 amount) external returns (uint);

}
