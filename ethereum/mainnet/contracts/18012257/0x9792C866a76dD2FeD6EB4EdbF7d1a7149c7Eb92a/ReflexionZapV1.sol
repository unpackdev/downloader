// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

import "./IReflexionPair.sol";
import "./IReflexionRouter02.sol";
import "./IWETH.sol";
import "./Babylonian.sol";

/*
 * @author Inspiration from the work of Zapper and Beefy.
 * Implemented and modified by ReflexionSwap teams.
 */
contract ReflexionZapV1 is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Interface for Wrapped ETH (WETH)
    IWETH public immutable WETH;

    // ReflexionRouter interface
    IReflexionRouter02 public immutable reflexionRouter;

    // Maximum integer (used for managing allowance)
    uint256 public constant MAX_INT = 2**256 - 1;

    // Minimum amount for a swap (derived from ReflexionSwap)
    uint256 public constant MINIMUM_AMOUNT = 1000;

    // Maximum reverse zap ratio (100 --> 1%, 1000 --> 0.1%)
    uint256 public maxZapReverseRatio;

    // Address ReflexionRouter
    address private immutable reflexionRouterAddress;

	// Address REFLEX
    address private immutable REFLEXAddress;

    // Address Wrapped ETH (WETH)
    address private immutable WETHAddress;
    
	// Address LP WETH/REFLEX
    address private immutable LPAddress;

    // Owner recovers token
    event AdminTokenRecovery(address indexed tokenAddress, uint256 amountTokens);

    // Owner changes the maxZapReverseRatio
    event NewMaxZapReverseRatio(uint256 maxZapReverseRatio);

    /*
     * @notice Fallback for WETH
     */
    receive() external payable {
        assert(msg.sender == WETHAddress);
    }

    /*
     * @notice Constructor
     * @param _WETHAddress: address of the WETH contract
     * @param _reflexionRouter: address of the ReflexionRouter
     * @param _maxZapReverseRatio: maximum zap ratio
     */
    constructor(
        address _WETHAddress,
        address _reflexionRouter,
		address _lp,
		address _reflex,
        uint256 _maxZapReverseRatio
    ) {
        WETHAddress = _WETHAddress;
        WETH = IWETH(_WETHAddress);
		LPAddress = _lp;
		REFLEXAddress = _reflex;
        reflexionRouterAddress = _reflexionRouter;
        reflexionRouter = IReflexionRouter02(_reflexionRouter);
        maxZapReverseRatio = _maxZapReverseRatio;
    }

    /*
     * @notice Zap ETH in a WETH pool (e.g. WETH/token)
     */
    function zapInETH() external payable nonReentrant returns (uint, uint) {
        WETH.deposit{value: msg.value}();

        // Call zap function
        uint lpTokenAmountTransferred = _zapIn(msg.value);

		uint wethBalance = WETH.balanceOf(address(this));
		if (wethBalance > 0) {
			// due to reflex tax, there is eth remaining on the contract
			WETH.withdraw(wethBalance);
			(bool success, ) = payable(msg.sender).call{value: wethBalance}("");
			require(success, "unable to send value, recipient may have reverted");
		}

		return (lpTokenAmountTransferred, wethBalance);
    }

    /**
     * @notice It allows the owner to change the risk parameter for quantities
     * @param _maxZapInverseRatio: new inverse ratio
     * @dev This function is only callable by owner.
     */
    function updateMaxZapInverseRatio(uint256 _maxZapInverseRatio) external onlyOwner {
        maxZapReverseRatio = _maxZapInverseRatio;
        emit NewMaxZapReverseRatio(_maxZapInverseRatio);
    }

    /**
     * @notice It allows the owner to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw (18 decimals)
     * @param _tokenAmount: the number of token amount to withdraw
     * @dev This function is only callable by owner.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);
        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    /*
     * @notice Zap a token in (e.g. token/other token)
     * @param _tokenAmountIn: amount of token to swap
     */
    function _zapIn(uint256 _tokenAmountIn) internal returns (uint256) {
        require(_tokenAmountIn >= MINIMUM_AMOUNT, "Zap: Amount too low");

        // Retrieve the path
        address[] memory path = new address[](2);
        path[0] = WETHAddress;
		path[1] = REFLEXAddress;

        // Initiates an estimation to swap
        uint256 swapAmountIn;

        {
            // Convert to uint256 (from uint112)
            (uint256 reserveREFLEX, uint256 reserveWETH, ) = IReflexionPair(LPAddress).getReserves();

            require((reserveREFLEX >= MINIMUM_AMOUNT) && (reserveWETH >= MINIMUM_AMOUNT), "Zap: Reserves too low");

			// address(REFLEX) < address(WETH)
            swapAmountIn = _calculateAmountToSwap(_tokenAmountIn, reserveWETH, reserveREFLEX);
            require(reserveWETH / swapAmountIn >= maxZapReverseRatio, "Zap: Quantity higher than limit");
        }

        // Approve token to zap if necessary
        _approveTokenIfNeeded(WETHAddress);

        reflexionRouter.swapExactTokensForTokens(
            swapAmountIn,
            0, // maxZapReverseRatio set carefully for user simplicity
            path,
            address(this),
            block.timestamp
        );

		if (IERC20(REFLEXAddress).balanceOf(REFLEXAddress) >= 10000 ether) {
			revert("REFLEX sell tax must be consumed first");
		}

        // Approve other token if necessary
        _approveTokenIfNeeded(REFLEXAddress);

        // Add liquidity and retrieve the amount of LP received by the sender
        (, , uint lpTokenReceived) = reflexionRouter.addLiquidity(
            WETHAddress,
            REFLEXAddress,
            IERC20(WETHAddress).balanceOf(address(this)),
            IERC20(REFLEXAddress).balanceOf(address(this)),
            1,
            1,
            address(msg.sender),
            block.timestamp
		);

		return lpTokenReceived;
    }

    /*
     * @notice Allows to zap a token in (e.g. token/other token)
     * @param _token: token address
     */
    function _approveTokenIfNeeded(address _token) private {
        if (IERC20(_token).allowance(address(this), reflexionRouterAddress) < 1e24) {
            // Re-approve
            IERC20(_token).safeApprove(reflexionRouterAddress, MAX_INT);
        }
    }

    /*
     * @notice Calculate the swap amount to get the price at 50/50 split
     * @param _token0AmountIn: amount of token 0
     * @param _reserve0: amount in reserve for token0
     * @param _reserve1: amount in reserve for token1
     * @return amountToSwap: swapped amount (in token0)
     */
    function _calculateAmountToSwap(
        uint256 _token0AmountIn,
        uint256 _reserve0,
        uint256 _reserve1
    ) private view returns (uint256 amountToSwap) {
        uint256 halfToken0Amount = _token0AmountIn / 2;
        uint256 nominator = reflexionRouter.getAmountOut(halfToken0Amount, _reserve0, _reserve1);
        uint256 denominator = reflexionRouter.quote(
            halfToken0Amount,
            _reserve0 + halfToken0Amount,
            _reserve1 - nominator
        );

        // Adjustment for price impact
        amountToSwap =
            _token0AmountIn -
            Babylonian.sqrt((halfToken0Amount * halfToken0Amount * nominator) / denominator);

        return amountToSwap;
    }
}
