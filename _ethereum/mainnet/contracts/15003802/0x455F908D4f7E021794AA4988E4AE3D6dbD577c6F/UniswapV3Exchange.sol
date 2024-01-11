// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;
pragma abicoder v2;

import "./SafeERC20.sol";
import "./IQuoter.sol";
import "./PoolAddress.sol";
import "./ISwapRouter.sol";
import "./Path.sol";
import "./IExchange.sol";

/**
 * @title UniswapV3 Exchange
 */
contract UniswapV3Exchange is IExchange {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SafeMath for uint24;
    using Path for bytes;

    IQuoter internal constant QUOTER = IQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);
    ISwapRouter internal constant UNI3_ROUTER = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    uint24 public constant POOL_FEE_BPS = 1_000_000;
    address public constant UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

    address public immutable wethLike;
    uint24 public defaultPoolFee = 3000; // 0.3%

    /**
     * @dev Doesn't consider router.WETH() as `wethLike` because isn't guaranteed that it's the most liquid token.
     * For instance: On Polygon, the `WETH` is more liquid than `WMATIC` on UniV3 protocol.
     */
    constructor(address wethLike_) {
        wethLike = wethLike_;
    }

    /// @inheritdoc IExchange
    function getBestAmountIn(
        address tokenIn_,
        address tokenOut_,
        uint256 amountOut_
    ) external override returns (uint256 _amountIn, bytes memory _path) {
        // 1. Check IN-OUT pair if one of the tokens is WETH-like
        if (tokenIn_ == wethLike || tokenOut_ == wethLike) {
            _path = abi.encodePacked(tokenOut_, defaultPoolFee, tokenIn_);
            _amountIn = getAmountsIn(amountOut_, _path);
            require(_amountIn > 0, "no-path-found");
            return (_amountIn, _path);
        }

        // 2. Check IN-WETH-OUT path
        _path = abi.encodePacked(tokenOut_, defaultPoolFee, wethLike, defaultPoolFee, tokenIn_);
        _amountIn = getAmountsIn(amountOut_, _path);
        require(_amountIn > 0, "no-path-found");
        return (_amountIn, _path);
    }

    /// @inheritdoc IExchange
    function getBestAmountOut(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_
    ) external override returns (uint256 _amountOut, bytes memory _path) {
        // 1. Check IN-OUT pair if one of the tokens is WETH-like
        if (tokenIn_ == wethLike || tokenOut_ == wethLike) {
            _path = abi.encodePacked(tokenIn_, defaultPoolFee, tokenOut_);
            _amountOut = getAmountsOut(amountIn_, _path);
            require(_amountOut > 0, "no-path-found");
            return (_amountOut, _path);
        }

        // 2. Check IN-WETH-OUT path
        _path = abi.encodePacked(tokenIn_, defaultPoolFee, wethLike, defaultPoolFee, tokenOut_);
        _amountOut = getAmountsOut(amountIn_, _path);
        require(_amountOut > 0, "no-path-found");
    }

    /**
     * @notice Wraps `quoter.quoteExactOutput()` function
     * @dev Returns `0` if reverts
     */
    function getAmountsIn(uint256 amountOut_, bytes memory path_) public returns (uint256 _amountIn) {
        try QUOTER.quoteExactOutput(path_, amountOut_) returns (uint256 __amountIn) {
            _amountIn = __amountIn;
        } catch {}
    }

    /**
     * @notice Wraps `quoter.quoteExactInput()` function
     * @dev Returns `0` if reverts
     */
    function getAmountsOut(uint256 amountIn_, bytes memory path_) public returns (uint256 _amountOut) {
        try QUOTER.quoteExactInput(path_, amountIn_) returns (uint256 __amountOut) {
            _amountOut = __amountOut;
        } catch {}
    }

    /// @inheritdoc IExchange
    function swapExactInput(
        bytes calldata path_,
        uint256 amountIn_,
        uint256 amountOutMin_,
        address outReceiver_
    ) external override returns (uint256 _amountOut) {
        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: path_,
            recipient: outReceiver_,
            deadline: block.timestamp,
            amountIn: amountIn_,
            amountOutMinimum: amountOutMin_
        });

        (address _tokenInAddress, , ) = path_.decodeFirstPool();
        IERC20 _tokenIn = IERC20(_tokenInAddress);
        if (_tokenIn.allowance(address(this), address(UNI3_ROUTER)) < amountIn_) {
            _tokenIn.approve(address(UNI3_ROUTER), type(uint256).max);
        }
        _amountOut = UNI3_ROUTER.exactInput(params);
    }

    /// @inheritdoc IExchange
    function swapExactOutput(
        bytes calldata path_,
        uint256 amountOut_,
        uint256 amountInMax_,
        address remainingReceiver_,
        address outReceiver_
    ) external override returns (uint256 _amountIn) {
        address _tokenInAddress;
        if (path_.numPools() == 1) {
            (, _tokenInAddress, ) = path_.decodeFirstPool();
        } else if (path_.numPools() == 2) {
            (, _tokenInAddress, ) = path_.skipToken().decodeFirstPool();
        } else {
            revert("invalid-path-length");
        }

        IERC20 _tokenIn = IERC20(_tokenInAddress);
        if (_tokenIn.allowance(address(this), address(UNI3_ROUTER)) < amountInMax_) {
            _tokenIn.approve(address(UNI3_ROUTER), type(uint256).max);
        }

        ISwapRouter.ExactOutputParams memory params = ISwapRouter.ExactOutputParams({
            path: path_,
            recipient: outReceiver_,
            deadline: block.timestamp,
            amountOut: amountOut_,
            amountInMaximum: amountInMax_
        });

        _amountIn = UNI3_ROUTER.exactOutput(params);

        // If swap end up costly less than _amountInMax then return remaining to caller
        uint256 _remainingAmountIn = amountInMax_ - _amountIn;
        if (_remainingAmountIn > 0) {
            _tokenIn.safeTransfer(remainingReceiver_, _remainingAmountIn);
        }
    }
}
