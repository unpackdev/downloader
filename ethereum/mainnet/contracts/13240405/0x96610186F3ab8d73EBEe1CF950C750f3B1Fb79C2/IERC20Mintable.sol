// SPDX-License-Identifier: Apache-2.0
// Copyright 2021 Enjinstarter
pragma solidity ^0.7.6;

import "./IERC20.sol";

/**
 * @title IERC20Mintable
 * @author Enjinstarter
 */
interface IERC20Mintable is IERC20 {
    function mint(address account, uint256 amount) external;
}
