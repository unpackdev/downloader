// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./IERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeERC20.sol";

/**
 * @title Token swapping contract for swapping tokens from one contract to another
 * @author Onur Tekin
 */
contract TokenSwap is Ownable, Pausable {
    using SafeERC20 for IERC20;

    /// Token contract that is going to swap from
    IERC20 public immutable tokenSwapFrom;
    /// Token contract that is going to swap to
    IERC20 public immutable tokenSwapTo;

    /**
     * @dev Emitted when tokens are swapped
     * @param swapper The token swapper address
     * @param amount The amount of tokens that had been swapped
     */
    event Swapped(address indexed swapper, uint256 amount);

    constructor(address addressTokenSwapFrom, address addressTokenSwapTo) {
        require(addressTokenSwapFrom != address(0), "TokenSwap: tokenSwapFrom address cannot be zero");
        require(addressTokenSwapTo != address(0), "TokenSwap: tokenSwapTo address cannot be zero");

        tokenSwapFrom = IERC20(addressTokenSwapFrom);
        tokenSwapTo = IERC20(addressTokenSwapTo);
    }

    /**
     * @dev Swaps tokens from one contract to another
     * @param amount The amount of tokens that is going to be swapped
     */
    function swap(uint256 amount) external whenNotPaused {
        tokenSwapFrom.safeTransferFrom(msg.sender, address(this), amount);

        uint256 contractBalance = tokenSwapTo.balanceOf(address(this));
        require(contractBalance >= amount, "TokenSwap: contract balance is not enough to perform swap");

        tokenSwapTo.safeTransfer(msg.sender, amount);

        emit Swapped(msg.sender, amount);
    }

    /// @dev Pauses certain functions. See {Pausable-_pause}
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev Unpauses certain functions. See {Pausable-_unpause}
    function unpause() external onlyOwner {
        _unpause();
    }
}
