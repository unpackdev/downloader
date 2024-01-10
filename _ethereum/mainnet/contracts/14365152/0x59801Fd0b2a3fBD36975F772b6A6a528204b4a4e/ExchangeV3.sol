//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./IExchange.sol";
import "./ISwapV3Router.sol";
import "./ISwapV3Pool.sol";
import "./ISwapV3Factory.sol";

contract ExchangeV3 is IExchange, Ownable {

    using SafeMath for uint256;

    ISwapV3Router public router;

    ISwapV3Factory public factory;

    uint24 public poolFee = 3000; // 0.3%

    uint256 internal constant Q192 = 2 ** 192;

    constructor(address _router) {
        router = ISwapV3Router(_router);
        factory = ISwapV3Factory(router.factory());
    }

    function setRouter(address _router) external onlyOwner {
        router = ISwapV3Router(_router);
        factory = ISwapV3Factory(router.factory());
    }

    function setPoolFee(uint24 _poolFee) external onlyOwner {
        poolFee = _poolFee;
    }

    /// @inheritdoc IExchange
    function getEstimatedTokensForETH(IERC20 _token, uint256 _ethAmount) external view returns (uint256) {
        ISwapV3Pool pool = ISwapV3Pool(factory.getPool(address(_token), router.WETH9(), poolFee));

        (uint160 sqrtPriceX96,,,,,,) = pool.slot0();
        uint256 priceX96 = uint256(sqrtPriceX96) ** 2;

        uint256 tokensAmount = pool.token0() == router.WETH9() ? _ethAmount.mul(priceX96).div(Q192) : _ethAmount.mul(Q192).div(priceX96);
        uint256 feeAmount = tokensAmount.div(1000000).mul(poolFee);

        return tokensAmount.sub(feeAmount);
    }

    /// @inheritdoc IExchange
    function swapTokensToETH(IERC20 _token, uint256 _receiveEthAmount, uint256 _tokensMaxSpendAmount, address _ethReceiver, address _tokensReceiver) external returns (uint256) {
        // Approve tokens for router V3
        require(_token.approve(address(router), _tokensMaxSpendAmount), "Approve router for exchange v3 failed");

        ISwapV3Router.ExactOutputSingleParams memory params = ISwapV3Router.ExactOutputSingleParams({
        tokenIn : address(_token),
        tokenOut : router.WETH9(),
        fee : poolFee,
        recipient : address(router),
        deadline : block.timestamp,
        amountOut : _receiveEthAmount,
        amountInMaximum : _tokensMaxSpendAmount,
        sqrtPriceLimitX96 : 0
        });

        uint256 spentTokens = router.exactOutputSingle{value : 0}(params);

        // Unwrap WETH and send receiver
        router.unwrapWETH9(_receiveEthAmount, _ethReceiver);

        // Send rest of tokens to tokens receiver
        if (spentTokens < _tokensMaxSpendAmount) {
            require(_token.transfer(_tokensReceiver, _tokensMaxSpendAmount.sub(spentTokens)));
        }

        return spentTokens;
    }
}
