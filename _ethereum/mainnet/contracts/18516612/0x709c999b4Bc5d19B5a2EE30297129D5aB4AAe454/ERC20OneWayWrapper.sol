// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/ERC20Wrapper.sol)

pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./SafeERC20.sol";

/**
 * @dev Extension of the ERC20 token contract to support token wrapping.
 */
abstract contract ERC20OneWayWrapper is ERC20 {
    IERC20 private immutable _underlying;

    /**
     * @dev The underlying token couldn't be wrapped.
     */
    error ERC20InvalidUnderlying(address token);

    constructor(IERC20 underlyingToken) {
        if (underlyingToken == this) {
            revert ERC20InvalidUnderlying(address(this));
        }
        _underlying = underlyingToken;
    }

    /**
     * @dev Returns the address of the underlying ERC-20 token that is being wrapped.
     */
    function underlying() public view returns (IERC20) {
        return _underlying;
    }

    /**
     * @dev Allow a user to deposit underlying tokens and mint the corresponding number of wrapped tokens.
     */
    function depositFor(address account, uint256 value) public virtual returns (bool) {
        address sender = _msgSender();
        if (sender == address(this)) {
            revert ERC20InvalidSender(address(this));
        }
        if (account == address(this)) {
            revert ERC20InvalidReceiver(account);
        }

        // Check allowance
        uint256 allowance = _underlying.allowance(sender, address(this));
        if (allowance < value) {
            revert ERC20InsufficientAllowance(sender, allowance, value);
        }

        // Transfer
        SafeERC20.safeTransferFrom(_underlying, sender, address(this), value);

        // Mint
        _mint(account, value);
        return true;
    }
}