// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.13;

import "./IERC20.sol";
import "./IUniswapV3Pool.sol";
import "./IUniswapV3SwapCallback.sol";
import "./Pausable.sol";
import "./Ownable.sol";

contract SmartTradeUniV3 is IUniswapV3SwapCallback, Pausable, Ownable {
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    event SwapInfo(int256, int256);

    modifier NoDelegateCall() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _ ;
    }
    
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function masterSwap(
        address poolAddress,
        bool zeroForOne,
        int256 amountIn,
        uint256 amountOutMin,
        uint160 sqrtPriceLimitX96,
        uint256 blockHeightRequired
    ) external NoDelegateCall whenNotPaused returns (int256 amount0, int256 amount1) {
        require(amountIn > 0, "Amount to swap has to be larger than zero");
        require(block.number <= blockHeightRequired, 'Transaction too old');

        IUniswapV3Pool pool = IUniswapV3Pool(poolAddress);

        (amount0, amount1) = pool.swap(msg.sender,
                                        zeroForOne,
                                        amountIn,
                                        sqrtPriceLimitX96 == 0 ? (zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1)
                                                                       : sqrtPriceLimitX96,
                                        abi.encode(msg.sender, zeroForOne)
                                            );
        require(uint256(-(zeroForOne ? amount1 : amount0)) >= amountOutMin, 'Too little received');
        
        emit SwapInfo(amount0, amount1);
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external override {
        IUniswapV3Pool pool = IUniswapV3Pool(msg.sender);
        (address payer, bool zeroForOne) = abi.decode(data, (address, bool));

        if(zeroForOne)
        {
            IERC20(pool.token0()).transferFrom(payer, msg.sender, uint256(amount0Delta));
        }
        else
        {
            IERC20(pool.token1()).transferFrom(payer, msg.sender, uint256(amount1Delta));   
        }
    }
}