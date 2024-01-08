// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./Math.sol";
import "./Governable.sol";
import "./Salvageable.sol";
import "./PriceGuard.sol";

abstract contract LiquidityNexusBase is Ownable, Pausable, Governable, Salvageable, ReentrancyGuard, PriceGuard {
    using SafeERC20 for IERC20;

    address public constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public constant USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    /**
     * Only the owner is supposed to deposit USDC into this contract.
     */
    function depositCapital(uint256 amount) public onlyOwner {
        IERC20(USDC).safeTransferFrom(msg.sender, address(this), amount);
    }

    function depositAllCapital() external onlyOwner {
        depositCapital(IERC20(USDC).balanceOf(msg.sender));
    }

    /**
     * The owner can withdraw the unused USDC capital that they had deposited earlier.
     */
    function withdrawFreeCapital() public onlyOwner {
        uint256 balance = IERC20(USDC).balanceOf(address(this));
        if (balance > 0) {
            IERC20(USDC).safeTransfer(msg.sender, balance);
        }
    }

    /**
     * Pause will only prevent new ETH deposits (addLiquidity). Existing depositors will still
     * be able to removeLiquidity even when paused.
     */
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * Owner can disable the PriceGuard oracle in case of emergency
     */
    function pausePriceGuard() external onlyOwner {
        _pausePriceGuard(true);
    }

    function unpausePriceGuard() external onlyOwner {
        _pausePriceGuard(false);
    }

    /**
     * Owner can only salvage unrelated tokens that were sent by mistake.
     */
    function salvage(address[] memory tokens) external onlyOwner {
        _salvage(tokens);
    }

    receive() external payable {} // solhint-disable-line no-empty-blocks
}
