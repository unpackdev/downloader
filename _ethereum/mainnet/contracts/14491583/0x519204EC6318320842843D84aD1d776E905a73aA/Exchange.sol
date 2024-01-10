/// I just needed time alone with my own thoughts
/// Got treasures in my mind, but couldn't open up my own vault
/// My childlike creativity, purity, and honesty
/// Is honestly being crowded by these grown thoughts

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

import "./IBondingCurve.sol";
import "./IHyperobject.sol";
import "./ERC20.sol";
import "./ReentrancyGuard.sol";
import "./SafeTransferLib.sol";

/// @title Exchange
/// @author neuroswish
/// @notice Autonomous exchange for hyperobjects

contract Exchange is ERC20, ReentrancyGuard {

    // ======== Storage ========

    address public immutable factory; // Exchange factory address
    address public immutable bondingCurve; // Bonding curve address
    address public creator; // Hyperobject creator
    address public hyperobject; // Hyperobject address
    uint256 public reserveRatio; // Reserve ratio of token market cap to ETH pool
    uint256 public slopeInit; // Slope value to initialize supply
    uint256 public poolBalance; // ETH balance in contract pool
    uint256 public transactionShare; // Transaction share

    // ======== Errors ========

	/// @notice Thrown when function caller is unauthorized
	error Unauthorized();

	/// @notice Thrown when token or ETH input is invalid
	error InvalidValue();

    /// @notice Thrown when slippage input is invalid
	error InvalidSlippage();

    /// @notice Thrown when initial price input is insufficient
	error InsufficientInitialPrice();

    /// @notice Thrown when slippage occurs
	error Slippage();

    /// @notice Thrown when sell amount is invalid
	error InvalidSellAmount();

    /// @notice Thrown when user balance is insufficient
	error InsufficientBalance();

    /// @notice Thrown when pool balance is insufficient
	error InsufficientPoolBalance();

    // ======== Events ========

    /// @notice Emitted when tokens are purchased
	/// @param buyer Token buyer
    /// @param poolBalance Pool balance
    /// @param totalSupply Total supply
    /// @param tokens Tokens bought
    /// @param price ETH
    event Buy(
        address indexed buyer,
        uint256 poolBalance,
        uint256 totalSupply,
        uint256 tokens,
        uint256 price
    );

    /// @notice Emitted when tokens are sold
	/// @param seller Token seller
    /// @param poolBalance Pool balance
    /// @param totalSupply Total supply
    /// @param tokens Tokens sold
    /// @param eth ETH
    event Sell(
        address indexed seller,
        uint256 poolBalance,
        uint256 totalSupply,
        uint256 tokens,
        uint256 eth
    );

    /// @notice Emitted when tokens are sold
	/// @param redeemer Token redeemer
    event Redeem(
        address indexed redeemer
    );

    // ======== Constructor ========

    /// @notice Set factory and bonding curve addresses
    /// @param _factory Factory address
    /// @param _bondingCurve Bonding curve address
    constructor(address _factory, address _bondingCurve) ERC20("Verse", "VERSE", 18) {
        factory = _factory;
        bondingCurve = _bondingCurve;
    }

    // ======== Initializer ========

    /// @notice Initialize a new exchange
    /// @param _name Hyperobject name
    /// @param _symbol Hyperobject symbol
    /// @param _reserveRatio Reserve ratio
    /// @param _slopeInit Initial slope value to determine price curve
    /// @param _transactionShare Transaction share
    /// @param _hyperobject Hyperobject address
    /// @param _creator Hyperobject creator
    /// @dev Called by factory at time of deployment
    function initialize(
        string calldata _name,
        string calldata _symbol,
        uint256 _reserveRatio,
        uint256 _slopeInit,
        uint256 _transactionShare,
        address _hyperobject,
        address _creator
    ) external {
        if (msg.sender != factory) revert Unauthorized();
        name = _name;
        symbol = _symbol;
        reserveRatio = _reserveRatio;
        slopeInit = _slopeInit;
        transactionShare = _transactionShare;
        hyperobject = _hyperobject;
        creator = _creator;
    }

    // ======== Functions ========

    /// @notice Buy tokens with ETH
    /// @param _minTokensReturned Minimum tokens returned in case of slippage
    /// @dev Emits a Buy event upon success; callable by anyone
    function buy(uint256 _minTokensReturned) external payable {
        if (msg.value == 0) revert InvalidValue();
        if (_minTokensReturned == 0) revert InvalidSlippage();
        uint256 price = msg.value;
        uint256 creatorShare = splitShare(price);
        uint256 buyAmount = price - creatorShare;
        uint256 tokensReturned;
        if (totalSupply == 0 || poolBalance == 0) {
            if (buyAmount < 1 * (10**15)) revert InsufficientInitialPrice();
            tokensReturned = IBondingCurve(bondingCurve)
                .calculateInitializationReturn(buyAmount / (10**15), reserveRatio, slopeInit);
            tokensReturned = tokensReturned * (10**15);
        } else {
            tokensReturned = IBondingCurve(bondingCurve)
                .calculatePurchaseReturn(
                    totalSupply,
                    poolBalance,
                    reserveRatio,
                    buyAmount
                );
        }
        if (tokensReturned < _minTokensReturned) revert Slippage();
        _mint(msg.sender, tokensReturned);
        poolBalance += buyAmount;
        SafeTransferLib.safeTransferETH(payable(creator), creatorShare);
        emit Buy(msg.sender, poolBalance, totalSupply, tokensReturned, buyAmount);
    }

    /// @notice Sell market tokens for ETH
    /// @param _tokens Tokens to sell
    /// @param _minETHReturned Minimum ETH returned in case of slippage
    /// @dev Emits a Sell event upon success; callable by token holders
    function sell(uint256 _tokens, uint256 _minETHReturned)
        external
    {
        if (_tokens == 0) revert InvalidSellAmount();
        if (_tokens > balanceOf[msg.sender]) revert InsufficientBalance();
        if (poolBalance == 0) revert InsufficientPoolBalance();
        if (_minETHReturned == 0) revert InvalidSlippage();
        uint256 ethReturned = IBondingCurve(bondingCurve).calculateSaleReturn(
            totalSupply,
            poolBalance,
            reserveRatio,
            _tokens
        );
        uint256 creatorShare = splitShare(ethReturned);
        uint256 sellerShare = ethReturned - creatorShare;
        if (sellerShare < _minETHReturned) revert Slippage();
        _burn(msg.sender, _tokens);
        poolBalance -= ethReturned;
        SafeTransferLib.safeTransferETH(payable(msg.sender), sellerShare);
        SafeTransferLib.safeTransferETH(payable(creator), creatorShare);
        emit Sell(msg.sender, poolBalance, totalSupply, _tokens, ethReturned);
    }

    
    /// @notice Redeem ERC20 token for Hyperobject NFT
    /// @dev Mints NFT from Hyperobject contract for caller upon success; callable by token holders with at least 1 token
    function redeem() public {
        if (balanceOf[msg.sender] < (1 * (10**18))) revert InsufficientBalance();
        transfer(hyperobject, (1 * (10**18)));
        IHyperobject(hyperobject).mint(msg.sender);
        emit Redeem(msg.sender);
    }

    // ======== Utility Functions ========

    /// @notice Calculate share of ETH that goes to creator for each transaction
    /// @param _amount Amount to split
    /// @dev Calculates share based on 10000 basis points; called internally
    function splitShare(uint256 _amount) internal view returns (uint256 _share) {
        _share = (_amount * transactionShare) / 10000;
    }
    
}

