pragma solidity ^0.8.9;

import "./Initializable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";

import "./DepositWalletConfig.sol";

contract DepositWalletImpl is Initializable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    DepositWalletConfig config;

    constructor() {}

    receive() external payable {
        payable(config.hotWalletAddress()).transfer(address(this).balance);
    }

    function initialize(
        DepositWalletConfig config_
    ) public initializer {
        config = config_;

        // rescue fund if any
        _rescueAll();
    }

    function _rescueNative() internal {
        if (address(this).balance == 0) {
            return;
        }

        payable(config.hotWalletAddress()).transfer(address(this).balance);
    }

    function _rescueERC20(address token) internal {
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance == 0) {
            return;
        }

        IERC20(token).safeTransfer(config.hotWalletAddress(), balance);
    }

    function _rescueAll() internal {
        _rescueNative();

        // whitelist only
        for (uint256 i = 0; i < config.whitelistedTokenLength(); i++) {
            address token = config.whitelistedTokens(i);
            _rescueERC20(token);
        }
    }

    // Rescue fund
    function rescueNative() external nonReentrant {
        _rescueNative();
    }

    function rescuseERC20(address token) external nonReentrant {
        _rescueERC20(token);
    }

    function rescueAll() external nonReentrant {
        _rescueAll();
    }
}