// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
interface IERC20Burnable is IERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     */
    function burn(uint256 amount) external;

    /**
     * @dev Returns `decimal` of token.
     */
    function decimals() external view returns (uint8);
}
