// SPDX-License-Identifier: MIT
// Based on OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)
pragma solidity ^0.8.7;

/**
 * @dev Contract module that helps prevent reentrant swaps
 */
abstract contract WowmaxSwapReentrancyGuard {
    uint256 private constant _SWAP_IN_PROGRESS = 1;
    uint256 private constant _SWAP_NOT_IN_PROGRESS = 2;

    uint256 private _swapStatus;

    constructor() {
        _swapStatus = _SWAP_NOT_IN_PROGRESS;
    }

    /**
     * @dev Prevents a contract from calling swap, directly or indirectly
     */
    modifier reentrancyProtectedSwap() {
        _beforeSwap();
        _;
        _afterSwap();
    }

    /**
     * @dev Prevents operation from being called outside of swap
     */
    modifier onlyDuringSwap() {
        require(_swapStatus == _SWAP_IN_PROGRESS, "WOWMAX: not allowed outside of swap");
        _;
    }

    function _beforeSwap() private {
        require(_swapStatus != _SWAP_IN_PROGRESS, "WOWMAX: reentrant swap not allowed");
        _swapStatus = _SWAP_IN_PROGRESS;
    }

    function _afterSwap() private {
        _swapStatus = _SWAP_NOT_IN_PROGRESS;
    }
}
