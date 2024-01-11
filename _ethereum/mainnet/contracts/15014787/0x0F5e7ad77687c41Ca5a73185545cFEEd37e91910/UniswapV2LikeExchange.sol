// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IUniswapV2Router02.sol";
import "./Governable.sol";
import "./IExchange.sol";

/**
 * @notice UniswapV2 Like Exchange
 */
contract UniswapV2LikeExchange is IExchange, Governable {
    using SafeERC20 for IERC20;

    /**
     * @notice The WETH-Like token (a.k.a. Native Token)
     * @dev I.e. should be the most liquid token that offer best routers among trade pairs
     * @dev It's usually the wrapper token of the chain's native coin but it isn't always true
     * For instance: On Polygon, the `WETH` is more liquid than `WMATIC` on UniV3 protocol.
     */
    address public wethLike;

    /**
     * @notice The UniswapV2-Like router contract
     */
    IUniswapV2Router02 public immutable router;

    /// @notice Emitted when wethLike token is updated
    event WethLikeTokenUpdated(address oldWethLike, address newWethLike);

    /**
     * @dev Doesn't consider router.WETH() as `wethLike` because isn't guaranteed that it's the most liquid token.
     */
    constructor(IUniswapV2Router02 router_, address wethLike_) {
        router = router_;
        wethLike = wethLike_;
    }

    /**
     * @notice Wraps `router.getAmountsIn()` function
     */
    function getAmountsIn(uint256 _amountOut, bytes memory path_) external view override returns (uint256 _amountIn) {
        uint256[] memory _amounts = router.getAmountsIn(_amountOut, _decodePath(path_));
        _amountIn = _amounts[0];
    }

    /**
     * @notice Wraps `router.getAmountsOut()` function
     */
    function getAmountsOut(uint256 amountIn_, bytes memory path_) external view override returns (uint256 _amountOut) {
        address[] memory _path = _decodePath(path_);
        uint256[] memory _amounts = router.getAmountsOut(amountIn_, _path);
        _amountOut = _amounts[_path.length - 1];
    }

    /// @inheritdoc IExchange
    function getBestAmountIn(
        address tokenIn_,
        address tokenOut_,
        uint256 amountOut_
    ) external returns (uint256 _amountIn, bytes memory _path) {
        // 1. Check IN-OUT pair
        address[] memory _pathA = new address[](2);
        _pathA[0] = tokenIn_;
        _pathA[1] = tokenOut_;
        uint256 _amountInA = _getAmountsIn(amountOut_, _pathA);

        if (tokenIn_ == wethLike || tokenOut_ == wethLike) {
            // Returns if one of the token is WETH-Like
            require(_amountInA > 0, "no-path-found");
            return (_amountInA, _encodePath(_pathA));
        }

        // 2. Check IN-WETH-OUT path
        address[] memory _pathB = new address[](3);
        _pathB[0] = tokenIn_;
        _pathB[1] = wethLike;
        _pathB[2] = tokenOut_;
        uint256 _amountInB = _getAmountsIn(amountOut_, _pathB);

        // 3. Get best route between paths A and B
        require(_amountInA > 0 || _amountInB > 0, "no-path-found");

        // Returns A if it's valid and better than B or if B isn't valid
        if ((_amountInA > 0 && _amountInA < _amountInB) || _amountInB == 0) {
            return (_amountInA, _encodePath(_pathA));
        }
        return (_amountInB, _encodePath(_pathB));
    }

    /// @inheritdoc IExchange
    function getBestAmountOut(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_
    ) external returns (uint256 _amountOut, bytes memory _path) {
        // 1. Check IN-OUT pair
        address[] memory _pathA = new address[](2);
        _pathA[0] = tokenIn_;
        _pathA[1] = tokenOut_;
        uint256 _amountOutA = _getAmountsOut(amountIn_, _pathA);

        if (tokenIn_ == wethLike || tokenOut_ == wethLike) {
            // Returns if one of the token is WETH-Like
            require(_amountOutA > 0, "no-path-found");
            return (_amountOutA, _encodePath(_pathA));
        }

        // 2. Check IN-WETH-OUT path
        address[] memory _pathB = new address[](3);
        _pathB[0] = tokenIn_;
        _pathB[1] = wethLike;
        _pathB[2] = tokenOut_;
        uint256 _amountOutB = _getAmountsOut(amountIn_, _pathB);

        // 3. Get best route between paths A and B
        require(_amountOutA > 0 || _amountOutB > 0, "no-path-found");
        if (_amountOutA > _amountOutB) return (_amountOutA, _encodePath(_pathA));
        return (_amountOutB, _encodePath(_pathB));
    }

    /// @inheritdoc IExchange
    function swapExactInput(
        bytes calldata path_,
        uint256 amountIn_,
        uint256 amountOutMin_,
        address outReceiver_
    ) external returns (uint256 _amountOut) {
        address[] memory _path = _decodePath(path_);
        IERC20 _tokenIn = IERC20(_path[0]);
        if (_tokenIn.allowance(address(this), address(router)) < amountIn_) {
            _tokenIn.approve(address(router), type(uint256).max);
        }

        _amountOut = router.swapExactTokensForTokens(amountIn_, amountOutMin_, _path, outReceiver_, block.timestamp)[
            _path.length - 1
        ];
    }

    /// @inheritdoc IExchange
    function swapExactOutput(
        bytes calldata path_,
        uint256 amountOut_,
        uint256 amountInMax_,
        address inSender_,
        address outRecipient_
    ) external returns (uint256 _amountIn) {
        address[] memory _path = _decodePath(path_);
        IERC20 _tokenIn = IERC20(_path[0]);
        if (_tokenIn.allowance(address(this), address(router)) < amountInMax_) {
            _tokenIn.approve(address(router), type(uint256).max);
        }

        _amountIn = router.swapTokensForExactTokens(amountOut_, amountInMax_, _path, outRecipient_, block.timestamp)[0];
        // If swap end up costly less than _amountInMax then return remaining
        uint256 _remainingAmountIn = amountInMax_ - _amountIn;
        if (_remainingAmountIn > 0) {
            _tokenIn.safeTransfer(inSender_, _remainingAmountIn);
        }
    }

    /**
     * @notice Wraps `router.getAmountsOut()` function
     * @dev Returns `0` if reverts
     */
    function _getAmountsOut(uint256 amountIn_, address[] memory path_) internal view returns (uint256 _amountOut) {
        try router.getAmountsOut(amountIn_, path_) returns (uint256[] memory amounts) {
            _amountOut = amounts[path_.length - 1];
        } catch {}
    }

    /**
     * @notice Wraps `router.getAmountsIn()` function
     * @dev Returns `0` if reverts
     */
    function _getAmountsIn(uint256 _amountOut, address[] memory _path) internal view returns (uint256 _amountIn) {
        try router.getAmountsIn(_amountOut, _path) returns (uint256[] memory amounts) {
            _amountIn = amounts[0];
        } catch {}
    }

    /**
     * @notice Encode path from `address[]` to `bytes`
     */
    function _encodePath(address[] memory path_) private pure returns (bytes memory _path) {
        return abi.encode(path_);
    }

    /**
     * @notice Encode path from `bytes` to `address[]`
     */
    function _decodePath(bytes memory path_) private pure returns (address[] memory _path) {
        return abi.decode(path_, (address[]));
    }

    /**
     * @notice Update WETH-Like token
     */
    function updateWethLikeToken(address wethLike_) external onlyGovernor {
        emit WethLikeTokenUpdated(wethLike, wethLike_);
        wethLike = wethLike_;
    }
}
