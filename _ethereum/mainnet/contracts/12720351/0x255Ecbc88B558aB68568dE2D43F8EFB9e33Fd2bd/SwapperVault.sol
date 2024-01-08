// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";

import "./IERC20.sol";
import "./SafeERC20.sol";

/**
 * @dev `deposit` source token and `claim` target token from NonLinearTimeLock contract.
 */
contract SwapperVault is Ownable, Pausable {
    using SafeERC20 for IERC20;

    IERC20 public token;
    address public swapper;

    event SwapperChanged(address swapper);

    modifier onlyValidAddress(address account) {
        require(account != address(0), "zero-address");
        _;
    }

    /**
     * @dev swapper address can be zero address if not deployed yet
     */
    constructor(IERC20 token_, address swapper_) onlyValidAddress(address(token_)) {
        swapper = swapper_;
        token = token_;

        if (swapper_ != address(0)) {
            _approveToSwapper(address(0), swapper_);
        }
    }

    function setSwapper(address swapper_) external whenNotPaused onlyOwner onlyValidAddress(swapper_) {
        address previousSwapper = swapper;
        swapper = swapper_;
        _approveToSwapper(previousSwapper, swapper_);
        emit SwapperChanged(swapper_);
    }

    function _approveToSwapper(address previousSwapper, address newSwapper) internal {
        if (previousSwapper != address(0)) {
            token.approve(previousSwapper, 0);
        }
        token.approve(newSwapper, type(uint256).max);
    }

    /****************************************************************
     *
     * Circuit Breaker
     *
     ****************************************************************/

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function claimTokens(address token_) external onlyOwner whenPaused {
        if (address(token_) == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
            return;
        }

        IERC20(token_).safeTransfer(msg.sender, IERC20(token_).balanceOf(address(this)));
    }
}
