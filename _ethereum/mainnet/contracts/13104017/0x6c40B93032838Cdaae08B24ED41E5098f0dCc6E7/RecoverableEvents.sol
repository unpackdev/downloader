
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* INTERFACE IMPORTS */

import "./IERC20.sol";

interface RecoverableEvents {
    
    /**
     * @dev Emitted when `account` recovers an `amount` ot `token`.
     */
    event Recovered(address account, IERC20 token, uint256 amount);

}