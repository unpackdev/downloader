// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* INTERFACE IMPORTS */

import "./IERC20.sol";

/* INHERITANCE IMPORTS */

import "./Context.sol";
import "./RecoverableEvents.sol";


contract Recoverable is Context, RecoverableEvents {
    /**
     * @param token - the token contract address to recover
     * @param amount - number of tokens to be recovered
     */
    function _recover(IERC20 token, uint256 amount) internal virtual {
        require(token.balanceOf(address(this)) >= amount, "Recoverable.recover: INVALID_AMOUNT");
        token.transfer(_msgSender(), amount);
        emit Recovered(_msgSender(), token, amount);
    }
}