// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

interface IDividends {
    function addDividendsToPending(address token, uint256 amount) external;
}

interface IStrategy {
    function mintByRevenue() external returns (uint256 _fTokenMinted, uint256 _xTokenMinted);
}

contract RevenueVault is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public dividends;
    address public strategy;

    event DividendsChanged(address indexed dividends);
    event StrategyChanged(address indexed strategy);

    function initialize() public initializer {
        __Ownable_init();
    }

    function setDividends(address _dividends) external onlyOwner {
        require(_dividends != address(0), "Dividends cannot be set to zero address");
        dividends = _dividends;
        emit DividendsChanged(dividends);
    }

    function setStrategy(address _strategy) external onlyOwner {
        require(_strategy != address(0), "Strategy cannot be set to zero address");
        strategy = _strategy;
        emit StrategyChanged(strategy);
    }

    function setReward(address token, uint256 amount) external onlyOwner {
        require(token != address(0), "reward token is zero address");
        require(amount > 0, "amount is zero");
        require(dividends != address(0), "Dividends is zero address");

        // mint fToken and xToken then transfer all of the minted amount to this contract
        if (strategy != address(0)) {
            IStrategy(strategy).mintByRevenue();
        }

        uint256 tokenBalance = IERC20Upgradeable(token).balanceOf(address(this));
        require(amount <= tokenBalance, "amount exceeds the maximum balance");

        uint256 allowance = IERC20Upgradeable(token).allowance(address(this), dividends);
        if (allowance < amount) {
            IERC20Upgradeable(token).safeApprove(dividends, type(uint256).max);
        }

        IDividends(dividends).addDividendsToPending(token, amount);
    }

    function setReward(address token) external onlyOwner {
        require(token != address(0), "reward token is zero address");
        require(dividends != address(0), "Dividends is zero address");

        // mint fToken and xToken then transfer all of the minted amount to this contract
        if (strategy != address(0)) {
            IStrategy(strategy).mintByRevenue();
        }

        uint256 amount = IERC20Upgradeable(token).balanceOf(address(this));
        require(amount > 0, "amount is zero");

        uint256 allowance = IERC20Upgradeable(token).allowance(address(this), dividends);
        if (allowance < amount) {
            IERC20Upgradeable(token).safeApprove(dividends, type(uint256).max);
        }

        IDividends(dividends).addDividendsToPending(token, amount);
    }

    function emergencyWithdraw(IERC20Upgradeable token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "token balance is 0");

        IERC20Upgradeable(token).safeTransfer(msg.sender, balance);
    }
}
