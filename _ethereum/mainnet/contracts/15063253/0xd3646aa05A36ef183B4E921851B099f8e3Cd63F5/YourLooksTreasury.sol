// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";

import "./IFeeSharingSystem.sol";
import "./ISwapRouter.sol";
import "./IWETH.sol";

/**
 * @title YourLooksTreasury
 * @notice It sells Royalty Fee to LOOKS using Uniswap V3.
 */
contract YourLooksTreasury is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // FeeSharingSystem (handles the distribution of WETH for LOOKS stakers)
    IFeeSharingSystem public immutable feeSharingSystem;

    // Router of Uniswap v3
    ISwapRouter public immutable uniswapRouter;

    // Wrapped Ether
    IWETH public immutable WETH;

    // Minimum deposit in LOOKS (it is derived from the FeeSharingSystem)
    uint256 public immutable MINIMUM_DEPOSIT_LOOKS;

    // LooksRare Token (LOOKS)
    IERC20 public immutable looksRareToken;

    // Reward token (WETH)
    IERC20 public immutable rewardToken;

    // Trading fee on Uniswap v3 (e.g., 3000 ---> 0.3%)
    uint24 public tradingFeeUniswapV3;

    // Last harvest action block
    uint256 public lastHarvestBlock;

    // Last contract action block
    uint256 public lastCompoundBlock;

    // Maximum price of LOOKS (in WETH) multiplied 1e18 (e.g., 0.0004 ETH --> 4e14)
    uint256 public maxPriceLOOKSInWETH;

    // Threshold amount (in rewardToken)
    uint256 public thresholdAmount;

    // Allocation WETH
    address public rewardSplitter;

    event Received(address, uint256);
    event Deposit(uint256 amount);
    event ConversionToLOOKS(uint256 amountSold, uint256 amountReceived);
    event FailedConversion();
    event HarvestToRewardSplitter(uint256 amountToTransfer);
    event NewMaximumPriceLOOKSInWETH(uint256 maxPriceLOOKSInWETH);
    event NewThresholdAmount(uint256 thresholdAmount);
    event NewTradingFeeUniswapV3(uint24 tradingFeeUniswapV3);
    event Withdraw(uint256 amount);
    event WithdrawnToOwner(uint256 amount);

    /**
     * @notice Constructor
     * @param _feeSharingSystem address of the fee sharing system contract
     * @param _uniswapRouter address of the Uniswap v3 router
     * @param _looksRareToken address of the token staked (LOOKS)
     * @param _rewardToken address of the reward token
     */
    constructor(
        address _feeSharingSystem,
        address _uniswapRouter,
        address _looksRareToken,
        address _rewardToken
    ) {
        feeSharingSystem = IFeeSharingSystem(_feeSharingSystem);
        uniswapRouter = ISwapRouter(_uniswapRouter);
        WETH = IWETH(_rewardToken);

        looksRareToken = IERC20(_looksRareToken);
        rewardToken = IERC20(_rewardToken);

        tradingFeeUniswapV3 = 3000;
        MINIMUM_DEPOSIT_LOOKS = 10**18;
    }

    /**
     * @notice Deposit LOOKS tokens
     * @param amount amount to deposit (in LOOKS)
     * @dev Only callable by owner.
     */
    function deposit(uint256 amount) external nonReentrant onlyOwner {
        feeSharingSystem.deposit(amount, false);

        emit Deposit(amount);
    }

    /**
     * @notice Harvest pending WETH and transfer to reward splitter contract
     */
    function harvest() external nonReentrant whenNotPaused {
        require(block.number != lastHarvestBlock, "Harvest: Already done");

        _harvest();
    }

    /**
     * @notice Withdraw staked tokens
     * @param shares shares to withdraw
     * @dev Only callable by owner.
     */
    function withdraw(uint256 shares) external nonReentrant onlyOwner {
        feeSharingSystem.withdraw(shares, false);

        emit Withdraw(shares);
    }

    /**
     * @notice Withdraw all staked tokens
     * @dev Only callable by owner.
     */
    function withdrawAll() external nonReentrant onlyOwner {
        feeSharingSystem.withdrawAll(true);
    }

    /**
     * @notice Deposit ether to get wrapped ether
     * @dev Only callable by owner.
     */
    function WrapEther() external payable onlyOwner {
        WETH.deposit{value: address(this).balance}();
    }

    /**
     * @notice Harvest pending WETH, sell them to LOOKS, and deposit LOOKS (if possible)
     * @dev Only callable by owner.
     */
    function sellRoyaltyAndCompound() external nonReentrant onlyOwner {
        require(block.number != lastCompoundBlock, "Compound: Already done");

        _sellRoyaltyAndCompound();
    }

    /**
     * @notice Adjust allowance if necessary
     * @dev Only callable by owner.
     */
    function checkAndAdjustLOOKSTokenAllowanceIfRequired() external onlyOwner {
        looksRareToken.approve(address(feeSharingSystem), type(uint256).max);
    }

    /**
     * @notice Adjust allowance if necessary
     * @dev Only callable by owner.
     */
    function checkAndAdjustRewardTokenAllowanceIfRequired() external onlyOwner {
        rewardToken.approve(address(uniswapRouter), type(uint256).max);
    }

    /**
     * @notice Update maximum price of LOOKS in WETH
     * @param _newMaxPriceLOOKSInWETH new maximum price of LOOKS in WETH times 1e18
     * @dev Only callable by owner
     */
    function updateMaxPriceOfLOOKSInWETH(uint256 _newMaxPriceLOOKSInWETH) external onlyOwner {
        maxPriceLOOKSInWETH = _newMaxPriceLOOKSInWETH;

        emit NewMaximumPriceLOOKSInWETH(_newMaxPriceLOOKSInWETH);
    }

    /**
     * @notice Adjust trading fee for Uniswap v3
     * @param _newTradingFeeUniswapV3 new tradingFeeUniswapV3
     * @dev Only callable by owner. Can only be 10,000 (1%), 3000 (0.3%), or 500 (0.05%).
     */
    function updateTradingFeeUniswapV3(uint24 _newTradingFeeUniswapV3) external onlyOwner {
        require(
            _newTradingFeeUniswapV3 == 10000 || _newTradingFeeUniswapV3 == 3000 || _newTradingFeeUniswapV3 == 500,
            "Owner: Fee invalid"
        );

        tradingFeeUniswapV3 = _newTradingFeeUniswapV3;

        emit NewTradingFeeUniswapV3(_newTradingFeeUniswapV3);
    }

    /**
     * @notice Adjust threshold amount for periodic Uniswap v3 WETH --> LOOKS conversion
     * @param _newThresholdAmount new threshold amount (in WETH)
     * @dev Only callable by owner
     */
    function updateThresholdAmount(uint256 _newThresholdAmount) external onlyOwner {
        thresholdAmount = _newThresholdAmount;

        emit NewThresholdAmount(_newThresholdAmount);
    }

    /**
     * @notice Pause
     * @dev Only callable by owner
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @notice Unpause
     * @dev Only callable by owner
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @notice Set reward splitter contract
     * @param _rewardSplitter address of reward splitter
     * @dev Only callable by owner
     */
    function setRewardSplitter(address _rewardSplitter) external onlyOwner {
        rewardSplitter = _rewardSplitter;
    }

    /**
     * @notice Transfer LOOKS tokens back to owner
     * @dev It is for emergency purposes. Only for owner.
     */
    function withdrawToOwner() external onlyOwner {
        uint256 amount = looksRareToken.balanceOf(address(this));

        looksRareToken.safeTransfer(owner(), amount);

        emit WithdrawnToOwner(amount);
    }

    /**
     * @dev Receive Ether to this contract.
     */
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /**
     * @dev Revert fallback calls
     */
    fallback() external payable {
        revert("Fallback not allowed");
    }

    /**
     * @notice Harvest pending WETH and transfer to reward splitter contract
     */
    function _harvest() internal {
        // Try/catch to prevent revertions if nothing to harvest
        try feeSharingSystem.harvest() {} catch {}

        uint256 amountToTransfer = rewardToken.balanceOf(address(this));

        rewardToken.safeTransfer(rewardSplitter, amountToTransfer);

        // Adjust last harvest block
        lastHarvestBlock = block.number;

        emit HarvestToRewardSplitter(amountToTransfer);
    }

    /**
     * @notice Sell royalty fee to LOOKS, and deposit LOOKS (if possible)
     */
    function _sellRoyaltyAndCompound() internal {
        uint256 amountToSell = rewardToken.balanceOf(address(this));

        if (amountToSell >= thresholdAmount) {
            bool isExecuted = _sellRoyaltyToLOOKS(amountToSell);

            if (isExecuted) {
                uint256 adjustedAmount = looksRareToken.balanceOf(address(this));

                if (adjustedAmount >= MINIMUM_DEPOSIT_LOOKS) {
                    feeSharingSystem.deposit(adjustedAmount, false);
                }
            }
        }

        // Adjust last harvest block
        lastCompoundBlock = block.number;
    }

    /**
     * @notice Sell WETH to LOOKS
     * @param _amount amount of rewardToken to convert (WETH)
     * @return whether the transaction went through
     */
    function _sellRoyaltyToLOOKS(uint256 _amount) internal returns (bool) {
        uint256 amountOutMinimum = maxPriceLOOKSInWETH != 0 ? (_amount * 1e18) / maxPriceLOOKSInWETH : 0;

        // Set the order parameters
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
            address(rewardToken), // tokenIn
            address(looksRareToken), // tokenOut
            tradingFeeUniswapV3, // fee
            address(this), // recipient
            block.timestamp, // deadline
            _amount, // amountIn
            amountOutMinimum, // amountOutMinimum
            0 // sqrtPriceLimitX96
        );

        // Swap on Uniswap V3
        try uniswapRouter.exactInputSingle(params) returns (uint256 amountOut) {
            emit ConversionToLOOKS(_amount, amountOut);
            return true;
        } catch {
            emit FailedConversion();
            return false;
        }
    }
}
