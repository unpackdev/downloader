/// Copyright (C) 2022 Portals.fi

/// @author Portals.fi
/// @notice This contract adds liquidity and stakes liquiditity into Convex like pools using any ERC20 token or the network token.

/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import "./PortalBaseV1.sol";
import "./IPortalRegistry.sol";
import "./IBaseRewardPool.sol";
import "./IBooster.sol";

/// Thrown when insufficient liquidity is received after deposit
/// @param buyAmount The amount of liquidity received
/// @param minBuyAmount The minimum acceptable quantity of liquidity received
error InsufficientBuy(uint256 buyAmount, uint256 minBuyAmount);

contract ConvexPortalIn is PortalBaseV1 {
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    IBooster internal immutable BOOSTER;

    /// @notice Emitted when a portal is entered
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to Portal in
    /// @param buyToken The ERC20 token address to buy (address(0) if network token)
    /// @param buyAmount The quantity of buyToken received
    /// @param fee The fee in BPS
    /// @param sender The  msg.sender
    /// @param partner The front end operator address
    event PortalIn(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 buyAmount,
        uint256 fee,
        address indexed sender,
        address indexed partner
    );

    constructor(
        bytes32 protocolId,
        PortalType portalType,
        IPortalRegistry registry,
        address exchange,
        address wrappedNetworkToken,
        uint256 fee,
        IBooster _booster
    )
        PortalBaseV1(
            protocolId,
            portalType,
            registry,
            exchange,
            wrappedNetworkToken,
            fee
        )
    {
        BOOSTER = _booster;
    }

    /// @notice Add liquidity and stake into Convex like pools with network tokens/ERC20 tokens
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to Portal in
    /// @param intermediateToken The intermediate token to swap to (must be the underlying LP token)
    /// @param buyToken The Convex like deposit token address (i.e. the cvxToken)
    /// @param minBuyAmount The minimum quantity of buyTokens to receive. Reverts otherwise
    /// note: crv tokens are 1:1 with cvx tokens
    /// @param target The excecution target for the intermediate swap
    /// @param data  The encoded call for the intermediate swap
    /// @param partner The front end operator address
    /// @param rewardPool The base reward pool for the buyToken
    /// @return buyAmount The quantity of buyToken acquired
    /// @dev buyAmount is staked and not returned to msg.sender!
    function portalIn(
        address sellToken,
        uint256 sellAmount,
        address intermediateToken,
        address buyToken,
        uint256 minBuyAmount,
        address target,
        bytes calldata data,
        address partner,
        IBaseRewardPool rewardPool
    ) external payable pausable returns (uint256 buyAmount) {
        uint256 amount = _transferFromCaller(sellToken, sellAmount);
        amount = _getFeeAmount(amount, fee);
        amount = _execute(sellToken, amount, intermediateToken, target, data);

        buyAmount = _deposit(intermediateToken, amount, buyToken, rewardPool);

        if (buyAmount < minBuyAmount)
            revert InsufficientBuy(buyAmount, minBuyAmount);

        _stake(buyToken, buyAmount, rewardPool);

        emit PortalIn(
            sellToken,
            sellAmount,
            buyToken,
            buyAmount,
            fee,
            msg.sender,
            partner
        );
    }

    /// @notice Deposits the Underlying LP (e.g. Curve LP) into the pool
    /// @param intermediateToken The underlying LP token to deposit
    /// @param amount The quantity of intermediateToken to deposit
    /// @param buyToken The Convex like deposit token address (i.e. the cvxToken)
    /// @param rewardPool The base reward pool for the buyToken
    function _deposit(
        address intermediateToken,
        uint256 amount,
        address buyToken,
        IBaseRewardPool rewardPool
    ) internal returns (uint256 buyAmount) {
        uint256 pid = rewardPool.pid();

        uint256 balance = _getBalance(address(this), buyToken);

        _approve(intermediateToken, address(BOOSTER), amount);
        BOOSTER.deposit(pid, amount, false);

        buyAmount = _getBalance(address(this), buyToken) - balance;
    }

    /// @notice Stakes the cvxToken into the reward pool
    /// @param buyToken The Convex like deposit token address (i.e. the cvxToken)
    /// @param buyAmount The quantity of buyToken to deposit
    /// @param rewardPool The base reward pool for the buyToken
    function _stake(
        address buyToken,
        uint256 buyAmount,
        IBaseRewardPool rewardPool
    ) internal {
        _approve(buyToken, address(rewardPool), buyAmount);
        rewardPool.stakeFor(msg.sender, buyAmount);
    }
}
