// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.4;
import "./IERC20Upgradeable.sol";
import "./PreciseUnitMath.sol";
import "./SafeMathUpgradeable.sol";
import "./IPriceFeed.sol";
import "./IUniswapV2Router02.sol";
import "./AggregatorV3Interface.sol";

abstract contract AbstractDistributor {
    using SafeMathUpgradeable for uint256;
    event BuyCoverEvent(
        address _productAddress,
        uint256 _productId,
        uint256 _period,
        address _asset,
        uint256 _amount,
        uint256 _price
    );

    uint256 constant SECONDS_IN_THE_YEAR = 365 * 24 * 60 * 60; // 365 days * 24 hours * 60 minutes * 60 seconds*//*
    uint256 constant MAX_INT = type(uint256).max;

    uint256 constant DECIMALS18 = 10**18;

    uint256 constant PRECISION = 10**25;
    uint256 constant PERCENTAGE_100 = 100 * PRECISION;

    uint256 constant BLOCKS_PER_DAY = 6450;
    uint256 constant BLOCKS_PER_YEAR = BLOCKS_PER_DAY * 365;

    uint256 constant APY_TOKENS = DECIMALS18;
    address constant ETH = (0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function _swapTokenForToken(
        address _priceFeed,
        uint256 _amountIn,
        address _from,
        address _to,
        address _via
    ) internal returns (uint256) {
        if (_amountIn == 0) {
            return 0;
        }

        address[] memory pairs;

        if (_via == address(0)) {
            pairs = new address[](2);
            pairs[0] = _from;
            pairs[1] = _to;
        } else {
            pairs = new address[](3);
            pairs[0] = _from;
            pairs[1] = _via;
            pairs[2] = _to;
        }

        uint256 _expectedOut = IPriceFeed(_priceFeed).howManyTokensAinB(
            _to,
            _from,
            _via,
            _amountIn,
            false
        );
        uint256 _amountOutMin = _expectedOut.mul(99).div(100);
        address _uniswapRouter = IPriceFeed(_priceFeed).getUniswapRouter();

        return
            IUniswapV2Router02(_uniswapRouter).swapExactTokensForTokens(
                _amountIn,
                _amountOutMin,
                pairs,
                address(this),
                block.timestamp.add(600)
            )[pairs.length.sub(1)];
    }

    function _swapExactETHForTokens(
        address _priceFeed,
        address _token,
        uint256 _amountIn
    ) internal returns (uint256) {
        IUniswapV2Router02 _uniswapRouter = IUniswapV2Router02(
            IPriceFeed(_priceFeed).getUniswapRouter()
        );
        address _wethToken = _uniswapRouter.WETH();
        address[] memory pairs = new address[](2);
        pairs[0] = address(_wethToken);
        pairs[1] = address(_token);

        uint256 _expectedOut;
        address _tokenFeed = IPriceFeed(_priceFeed).chainlinkAggregators(
            _token
        );
        if (_tokenFeed != address(0)) {
            (, int256 _price, , , ) = AggregatorV3Interface(_tokenFeed)
                .latestRoundData();
            _expectedOut = uint256(_price).mul(_amountIn).div(10**18);
        } else {
            _expectedOut = IPriceFeed(_priceFeed).internalPriceFeed(_token);
            _expectedOut = _expectedOut.mul(_amountIn).div(10**18);
        }
        uint256 _amountOutMin = _expectedOut.mul(99).div(100);
        return
            _uniswapRouter.swapETHForExactTokens{value: _amountIn}(
                _amountOutMin, //amountOutMin
                pairs,
                address(this),
                block.timestamp.add(600)
            )[pairs.length - 1];
    }

    function _checkApprovals(
        address _priceFeed,
        address _asset,
        uint256 _amount
    ) internal {
        address _uniswapRouter = IPriceFeed(_priceFeed).getUniswapRouter();
        if (
            IERC20Upgradeable(_asset).allowance(
                address(this),
                address(_uniswapRouter)
            ) < _amount
        ) {
            IERC20Upgradeable(_asset).approve(
                address(_uniswapRouter),
                PreciseUnitMath.MAX_UINT_256
            );
        }
    }
}
