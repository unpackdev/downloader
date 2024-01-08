// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IBank.sol";
import "./IStrategyBase.sol";
import "./ILiquidator.sol";
import "./IManager.sol";
import "./TransferHelper.sol";
import "./OhSubscriberUpgradeable.sol";
import "./OhStrategyStorage.sol";

/// @title Oh! Finance Strategy
/// @notice Base Upgradeable Strategy Contract to build strategies on
contract OhStrategy is OhSubscriberUpgradeable, OhStrategyStorage, IStrategyBase {
    using SafeERC20 for IERC20;

    event Liquidate(address indexed router, address indexed token, uint256 amount);
    event Sweep(address indexed token, uint256 amount, address recipient);

    /// @notice Only the Bank can execute these functions
    modifier onlyBank() {
        require(msg.sender == bank(), "Strategy: Only Bank");
        _;
    }

    /// @notice Initialize the base Strategy
    /// @param registry_ Address of the Registry
    /// @param bank_ Address of Bank
    /// @param underlying_ Underying token that is deposited
    /// @param derivative_ Derivative token received from protocol, or address(0)
    /// @param reward_ Reward token received from protocol, or address(0)
    function initializeStrategy(
        address registry_,
        address bank_,
        address underlying_,
        address derivative_,
        address reward_
    ) internal initializer {
        initializeSubscriber(registry_);
        initializeStorage(bank_, underlying_, derivative_, reward_);
    }

    /// @dev Balance of underlying awaiting Strategy investment
    function underlyingBalance() public view override returns (uint256) {
        return IERC20(underlying()).balanceOf(address(this));
    }

    /// @dev Balance of derivative tokens received from Strategy, if applicable
    /// @return The balance of derivative tokens
    function derivativeBalance() public view override returns (uint256) {
        if (derivative() == address(0)) {
            return 0;
        }
        return IERC20(derivative()).balanceOf(address(this));
    }

    /// @dev Balance of reward tokens awaiting liquidation, if applicable
    function rewardBalance() public view override returns (uint256) {
        if (reward() == address(0)) {
            return 0;
        }
        return IERC20(reward()).balanceOf(address(this));
    }

    /// @notice Governance function to sweep any stuck / airdrop tokens to a given recipient
    /// @param token The address of the token to sweep
    /// @param amount The amount of tokens to sweep
    /// @param recipient The address to send the sweeped tokens to
    function sweep(
        address token,
        uint256 amount,
        address recipient
    ) external onlyGovernance {
        // require(!_protected[token], "Strategy: Cannot sweep");
        TransferHelper.safeTokenTransfer(recipient, token, amount);
        emit Sweep(token, amount, recipient);
    }

    /// @dev Liquidation function to swap rewards for underlying
    function liquidate(
        address from,
        address to,
        uint256 amount
    ) internal {
        // if (amount > minimumSell())

        // find the liquidator to use
        address manager = manager();
        address liquidator = IManager(manager).liquidators(from, to);

        // increase allowance and liquidate to the manager
        TransferHelper.safeTokenTransfer(liquidator, from, amount);
        uint256 received = ILiquidator(liquidator).liquidate(manager, from, to, amount, 1);

        // notify revenue and transfer proceeds back to strategy
        IManager(manager).accrueRevenue(bank(), to, received);
    }
}
