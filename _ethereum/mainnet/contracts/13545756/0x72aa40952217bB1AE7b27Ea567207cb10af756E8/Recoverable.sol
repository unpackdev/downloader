// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./AccessControl.sol";
import "./Context.sol";

/**
 * @dev Contract module which allows for tokens to be recovered
 * Inheriters can customize recoverability of tokens by overriding the `canRecoverTokens` function
 * and
 */

abstract contract Recoverable is Context, AccessControl {

    using SafeERC20 for IERC20;

    bytes32 public constant RECOVERABLE_ADMIN_ROLE = keccak256("RECOVERABLE_ADMIN_ROLE");

    constructor() {
        _setupRole(RECOVERABLE_ADMIN_ROLE, _msgSender());
    }

    function recoverTokens(IERC20 token) public onlyRole(RECOVERABLE_ADMIN_ROLE)
    {
        require (canRecoverTokens(token));
        token.safeTransfer(_msgSender(), token.balanceOf(address(this)));
    }

    function canRecoverTokens(IERC20 token) internal virtual view returns (bool)
    {
        return address(token) != address(this);
    }
}
