// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.5;
pragma abicoder v2;

import "./ISwapRouter.sol";
import "./TransferHelper.sol";
import "./IQuoter.sol";
import "./IUniswapV3Pool.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IPeriphery.sol";
import "./IFactory.sol";
import "./IVault.sol";
import "./IERC20Metadata.sol";
import "./LongMath.sol";

/// @title Periphery
contract Periphery is IPeriphery {
    using SafeMath for uint256;
    using LongMath for uint256;
    using SafeERC20 for IERC20Metadata;
    using SafeERC20 for IVault;

    ISwapRouter public immutable swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IQuoter public immutable quoter = IQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);
    
    IFactory public factory;

    constructor(IFactory _factory) {
        factory = _factory;
    } 

    /// @inheritdoc IPeriphery
    function vaultDeposit(uint256 amount0In, uint256 amount1In, uint256 slippage, address strategy) 
    external override {
        require(slippage <= 100*100, "100% slippage is not allowed");

        (IVault vault, IUniswapV3Pool pool, IERC20Metadata token0, IERC20Metadata token1) = _getVault(strategy);

        // Calculate amount to swap based on tokens in vault
        // token0 / token1 = k
        // token0 + token1 * price = amountIn
        uint256 factor = 10 **
            (uint256(18).sub(token1.decimals()).add(token0.decimals()));

        (uint256 amountToSwap, bool direction) = _calculateAmountToSwap(vault, pool, factor, amount0In, amount1In);
        
        // transfer token0 from sender to contract & approve router to spend it
        IERC20Metadata(direction ? token0 : token1)
            .safeTransferFrom(msg.sender, address(this), direction ? amount0In : amount1In);

        // swap token0 for token1
        if(amountToSwap > 0) {
            uint256 amountOutQuotedWithSlippage = quoter.quoteExactInputSingle(
                address(direction ? token0 : token1), 
                address(direction ? token1 : token0), 
                pool.fee(), 
                amountToSwap, 
                0
            ).mul(100*100 - slippage).div(100*100);

            _swapTokens(
                direction, 
                address(token0), 
                address(token1), 
                pool.fee(), 
                amountToSwap, 
                amountOutQuotedWithSlippage 
            );
        }

        // deposit token0 & token1 in vault
        if(_tokenBalance(token0) > 0) {
            token0.approve(address(vault), _tokenBalance(token0));
        }
        if(_tokenBalance(token1) > 0) {
            token1.approve(address(vault), _tokenBalance(token1));
        }

        vault.deposit(
            _tokenBalance(direction ? token0 : token1), 
            _tokenBalance(direction ? token1 : token0), 
            0, 
            0, 
            msg.sender
        );

        // send balance of token1 & token0 to user
        _sendBalancesToUser(token0, token1, msg.sender);
    }

    /// @inheritdoc IPeriphery
    function vaultWithdraw(uint256 shares, address strategy, bool direction) 
    external override minimumAmount(shares) {
        (IVault vault, IUniswapV3Pool pool, IERC20Metadata token0, IERC20Metadata token1) = _getVault(strategy);

        // transfer shares from msg.sender & withdraw
        vault.safeTransferFrom(msg.sender, address(this), shares);
        (uint256 amount0, uint256 amount1) = vault.withdraw(shares, 0, 0, address(this));
        uint256 amountToSwap = direction ? amount0 : amount1;

        // swap token0 for token1
        if(amountToSwap > 0) {
            _swapTokens(
                direction, 
                address(token0), 
                address(token1), 
                pool.fee(), 
                amountToSwap, 
                0
            );
        }
 
        // send balance of token1 & token0 to user
        _sendBalancesToUser(token0, token1, msg.sender);
    }

    /**
      * @notice Get the balance of a token in contract
      * @param token token whose balance needs to be returned
      * @return balance of a token in contract
     */
    function _tokenBalance(IERC20Metadata token) internal view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
      * @notice Get the vault details from strategy address
      * @param strategy strategy to get manager vault from
      * @return vault, poolFee, token0, token1
     */
    function _getVault(address strategy) internal view 
        returns (IVault, IUniswapV3Pool, IERC20Metadata, IERC20Metadata) 
    {
        address vaultAddress = factory.managerVault(strategy);
        
        require(vaultAddress != address(0x0), "Not a valid strategy");

        IVault vault = IVault(vaultAddress);
        IUniswapV3Pool pool  = vault.pool();

        IERC20Metadata token0 = vault.token0();
        IERC20Metadata token1 = vault.token1();

        return (vault, pool, token0, token1);
    }

    /**
      * @notice Get the amount to swap befor deposit
      * @param vault vault to get token balances from
      * @param pool UniswapV3 pool
      * @param factor Constant factor to adjust decimals
      * @param amount0In minimum amount0 in
      * @param amount1In minimum amount1 in
      * @return amountToSwap amount to swap
      * @return isToken0Excess direction of swap
     */
    function _calculateAmountToSwap(IVault vault, IUniswapV3Pool pool, uint256 factor, uint256 amount0In, uint256 amount1In) internal view returns (uint256 amountToSwap, bool isToken0Excess) {
        (uint256 token0InVault, uint256 token1InVault) = vault.getTotalAmounts();

        if(token0InVault == 0 && token1InVault == 0) {
            amountToSwap = 0;
            isToken0Excess = amount1In == 0 ? true : false;
        } else if(token0InVault == 0 || token1InVault == 0) {
            isToken0Excess = token0InVault==0;
            amountToSwap = isToken0Excess ? amount0In : amount1In;
        } else {
            uint256 ratio = token1InVault.mul(factor).div(token0InVault);
            (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
            uint256 price = uint256(sqrtPriceX96).mul(uint256(sqrtPriceX96)).mul(
                factor
            ) >> (96 * 2);

            uint256 token0Converted = ratio.mul(amount0In).div(factor);
            isToken0Excess = amount1In < token0Converted;

            uint256 excessAmount = isToken0Excess ? token0Converted.sub(amount1In).mul(factor).div(ratio) : amount1In.sub(token0Converted);
            amountToSwap = isToken0Excess
                ? excessAmount.mul(ratio).div(price.add(ratio))
                : excessAmount.mul(price).div(price.add(ratio));
        }
    }

    /**
      * @notice send remaining balances of tokens to user
      * @param token0 token0 instance
      * @param token1 token1 instance
      * @param recipient address of recipient to receive balances
     */
    function _sendBalancesToUser(
        IERC20Metadata token0, 
        IERC20Metadata token1, 
        address recipient
    ) internal {
        if(_tokenBalance(token0) > 0) {
            token0.safeTransfer(recipient, _tokenBalance(token0));
        }
        if(_tokenBalance(token1) > 0) {
            token1.safeTransfer(recipient, _tokenBalance(token1));
        }
    }

    /**
      * @notice Swap tokens based on direction
      * @param direction direction to perform swap in
      * @param token0 token0 address
      * @param token1 token1 address
      * @param fee pool fee
      * @param amountIn amount to be swapped
      * @param amountOutMinimum Minimum output amount required
     */
    function _swapTokens(
        bool direction,
        address token0,
        address token1,
        uint24 fee,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) internal {
        IERC20Metadata(direction ? token0 : token1).approve(address(swapRouter), amountIn);

        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: direction ? token0 : token1,
                tokenOut:  direction ? token1 : token0,
                fee: fee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            });
        swapRouter.exactInputSingle(params);
    }

    modifier minimumAmount(uint256 amountIn) {
        require(amountIn > 0, "amountIn not sufficient");
        _;
    }
}