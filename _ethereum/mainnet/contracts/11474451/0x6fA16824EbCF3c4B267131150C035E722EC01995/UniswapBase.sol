// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";
import "./IAddressRegistry.sol";
import "./IWETH.sol";
import "./PatrolBase.sol";

abstract contract UniswapBase is PatrolBase {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public deadlineTime = 5 minutes;

    function _swapExactTokensForETH(
        uint256 _amount,
        address _token
    ) 
        internal
        NonZeroTokenBalance(_token)
        NonZeroAmount(_amount)
        returns (uint256)
    {
        require(
            IERC20(_token).balanceOf(address(this)) >= _amount,
            "Not enough tokens to swap"
        );

        address[] memory poolPath = new address[](2);
        poolPath[0] = address(_token);
        poolPath[1] = wethAddress();

        uint256 balanceBefore = address(this).balance;
        address uniswapRouter = uniswapRouterAddress();
        IERC20(_token).safeApprove(uniswapRouter, 0);
        IERC20(_token).safeApprove(uniswapRouter, _amount);
        IUniswapV2Router02(uniswapRouter).swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount, 
            0, 
            poolPath, 
            address(this), 
            _getDeadline()
        );
        return address(this).balance.sub(balanceBefore);
    }

    // swap eth for tokens, return amount of tokens bought
    function _swapExactETHForTokens(
        uint256 _amount,
        address _token
    ) 
        internal
        NonZeroAmount(_amount)
        returns (uint256)
    {
        address[] memory pwdrPath = new address[](2);
        pwdrPath[0] = wethAddress();
        pwdrPath[1] = _token;

        uint256 amountBefore = IERC20(_token).balanceOf(address(this));
        address uniswapRouter = uniswapRouterAddress();
        IERC20(wethAddress()).safeApprove(uniswapRouter, 0);
        IERC20(wethAddress()).safeApprove(uniswapRouter, _amount);
        IUniswapV2Router02(uniswapRouter)
            .swapExactETHForTokensSupportingFeeOnTransferTokens{ value: _amount }(
                0, 
                pwdrPath, 
                address(this), 
                _getDeadline()
            );
        return IERC20(_token).balanceOf(address(this)).sub(amountBefore);
    }

    // swap exact tokens for tokens, always using weth as middle address
    function _swapExactTokensForTokens(
        uint256 _amount,
        address _tokenIn,
        address _tokenOut
    )
        internal
        NonZeroTokenBalance(_tokenIn)
        returns (uint256)
    {
        address[] memory pwdrPath = new address[](3);
        pwdrPath[0] = _tokenIn; 
        pwdrPath[1] = wethAddress();
        pwdrPath[2] = _tokenOut;

        uint256 amountBefore = IERC20(_tokenOut).balanceOf(address(this));
        address uniswapRouter = uniswapRouterAddress();
        IERC20(_tokenIn).safeApprove(uniswapRouter, 0);
        IERC20(_tokenIn).safeApprove(uniswapRouter, _amount);
        IUniswapV2Router02(uniswapRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount,
            0, 
            pwdrPath, 
            address(this), 
            _getDeadline()
        );

        uint256 amountAfter = IERC20(_tokenOut).balanceOf(address(this));
        return amountAfter.sub(amountBefore);
    }

    // add liquidity on uniswap with _ethAmount, _tokenAmount to _token
    // return # lpTokens received
    function _addLiquidityETH(
        uint256 _ethAmount,
        uint256 _tokenAmount,
        address _token
    )
        internal
        NonZeroAmount(_ethAmount)
        NonZeroAmount(_tokenAmount)
        returns (uint256)
    {
        address uniswapRouter = IAddressRegistry(_addressRegistry).getUniswapRouter();

        IERC20(_token).safeApprove(uniswapRouter, 0);
        IERC20(_token).safeApprove(uniswapRouter, _tokenAmount);
        ( , , uint256 lpTokensReceived) = IUniswapV2Router02(uniswapRouter).addLiquidityETH{value: _ethAmount}(
            _token, 
            _tokenAmount, 
            0, 
            0, 
            address(this), 
            _getDeadline()
        );

        return lpTokensReceived;
    }
    
    // remove liquidity from _token with owned _amount LP token _lpToken
    function _removeLiquidityETH(
        uint256 _amount,
        address _lpToken,
        address _token
    ) 
        internal
        NonZeroAmount(_amount)
    {
        address uniswapRouter = uniswapRouterAddress();
        
        IERC20(_lpToken).safeApprove(uniswapRouter, 0);
        IERC20(_lpToken).safeApprove(uniswapRouter, _amount);
        IUniswapV2Router02(uniswapRouter).removeLiquidityETHSupportingFeeOnTransferTokens(
            _token, 
            _amount, 
            0, 
            0, 
            address(this), 
            _getDeadline()
        );
    }

    function _unwrapETH(uint256 _amount)
        internal
        NonZeroAmount(_amount)
    {
        IWETH(wethAddress()).withdraw(_amount);
    }

    // internal view function to view price of any token in ETH
    function _getTokenPrice(
        address _token,
        address _lpToken
    ) 
        public 
        view 
        returns (uint256) 
    {
        if (_token == wethAddress()) {
            return 1e18;
        }
        
        uint256 tokenBalance = IERC20(_token).balanceOf(_lpToken);
        if (tokenBalance > 0) {
            uint256 wethBalance = IERC20(wethAddress()).balanceOf(_lpToken);
            uint256 adjuster = 36 - uint256(ERC20(_token).decimals()); // handle non-base 18 tokens
            uint256 tokensPerEth = tokenBalance.mul(10**adjuster).div(wethBalance);
            return uint256(1e36).div(tokensPerEth); // price in gwei of token
        } else {
            return 0;
        }
    }

    function _getLpTokenPrice(address _lpToken)
        public
        view
        returns (uint256)
    {
        return IERC20(wethAddress()).balanceOf(_lpToken).mul(2).mul(1e18).div(IERC20(_lpToken).totalSupply());
    }

    function _getDeadline()
        internal
        view
        returns (uint256) 
    {
        return block.timestamp + 5 minutes;
    }
}