//SPDX-License-Identifier: BUSL
pragma solidity 0.8.10;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IExchange.sol";
import "./ISwapV3Router.sol";
import "./ISwapV3Pool.sol";
import "./ISwapV3Factory.sol";

contract ExchangeV3 is IExchange, Ownable {
    using SafeERC20 for IERC20;

    ISwapV3Router public router;
    ISwapV3Factory public factory;
    uint256 private constant FEE_DENOMINATOR = 1e6;
    uint24 public poolFee = 3000; // 0.3%
    uint256 internal constant Q192 = 2 ** 192;

    event RouterSet(address _router);
    event FactorySet(address _router);
    event PoolFeeSet(uint24 poolFee);

    constructor(address _router) {
        router = ISwapV3Router(_router);
        emit RouterSet(_router);
        address _factory = ISwapV3Router(_router).factory();
        factory = ISwapV3Factory(_factory);
        emit FactorySet(_factory);
    }

    function setRouter(address _router) external onlyOwner {
        router = ISwapV3Router(_router);
        emit RouterSet(_router);
        address _factory = ISwapV3Router(_router).factory();
        factory = ISwapV3Factory(_factory);
        emit FactorySet(_factory);
    }

    function setPoolFee(uint24 _poolFee) external onlyOwner {
        require(_poolFee < 10 * FEE_DENOMINATOR, "too high");  // < 1000%
        poolFee = _poolFee;
        emit PoolFeeSet(_poolFee);
    }

    /// @inheritdoc IExchange
    function getEstimatedTokensForETH(IERC20 _token, uint256 _ethAmount) external view returns (uint256) {
        ISwapV3Pool pool = ISwapV3Pool(factory.getPool(address(_token), router.WETH9(), poolFee));

        (uint160 sqrtPriceX96,,,,,,) = pool.slot0();
        uint256 priceX96 = uint256(sqrtPriceX96) ** 2;

        // proper testing required
        uint256 tokensAmount = pool.token0() == router.WETH9() ? _ethAmount * priceX96 / Q192 : _ethAmount * Q192 / priceX96;
        uint256 feeAmount = tokensAmount * poolFee / FEE_DENOMINATOR;

        return tokensAmount - feeAmount;
    }

    /// @inheritdoc IExchange
    function swapTokensToETH(IERC20 _token, uint256 _receiveEthAmount, uint256 _tokensMaxSpendAmount, address _ethReceiver, address _tokensReceiver) external returns (uint256) {
        // Approve tokens for router V3
        _token.safeApprove(address(router), _tokensMaxSpendAmount);

        ISwapV3Router.ExactOutputSingleParams memory params = ISwapV3Router.ExactOutputSingleParams({
            tokenIn: address(_token),
            tokenOut: router.WETH9(),
            fee: poolFee,
            recipient: address(router),
            deadline: block.timestamp,
            amountOut: _receiveEthAmount,
            amountInMaximum: _tokensMaxSpendAmount,
            sqrtPriceLimitX96: 0
        });

        uint256 spentTokens = router.exactOutputSingle(params);

        // Unwrap WETH and send receiver
        router.unwrapWETH9(_receiveEthAmount, _ethReceiver);

        // Send rest of tokens to tokens receiver
        if (spentTokens < _tokensMaxSpendAmount) {
            uint256 rest;
            unchecked {
                rest = _tokensMaxSpendAmount - spentTokens;
            }
            _token.safeTransfer(_tokensReceiver, rest);
        }

        _token.safeApprove(address(router), 0);

        return spentTokens;
    }
}
