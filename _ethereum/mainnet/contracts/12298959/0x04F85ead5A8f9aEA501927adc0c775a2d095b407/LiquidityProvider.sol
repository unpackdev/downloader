// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2ERC20.sol";
import "./IERC20.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./console.sol";
import "./ILiquidityProvider.sol";

contract LiquidityProvider is
    ILiquidityProvider,
    Initializable,
    OwnableUpgradeable
{
    struct API {
        IUniswapV2Router02 router;
        IUniswapV2Factory factory;
        IUniswapV2ERC20 wethToken;
    }

    event LiquidityAdded(
        address indexed _user,
        address indexed _lpToken,
        address token0,
        address token1,
        uint256 api,
        uint256 lpAmount,
        uint256 amountToken0,
        uint256 amountToken1
    );

    event LiquidityRemoved(
        address indexed _user,
        address indexed _lpToken,
        address token0,
        address token1,
        uint256 api,
        uint256 lpAmount,
        uint256 amountToken0,
        uint256 amountToken1,
        uint256 amountToken2
    );

    // API private apis;
    mapping(uint256 => API) public apis;
    uint256 private _apiCount;

    function addExchange(IUniswapV2Router02 _router) public onlyOwner {
        apis[_apiCount].router = _router;
        apis[_apiCount].factory = IUniswapV2Factory(
            apis[_apiCount].router.factory()
        );
        apis[_apiCount].wethToken = IUniswapV2ERC20(
            apis[_apiCount].router.WETH()
        );
        _apiCount++;
    }

    function initialize(IUniswapV2Router02 _router) public initializer {
        OwnableUpgradeable.__Ownable_init();
        addExchange(_router);
    }

    fallback() external payable {}

    receive() external payable {}

    function addLiquidityETH(
        address _token,
        address _to,
        uint256 _amountTokenMin,
        uint256 _amountETHMin,
        uint256 _minAmountOut,
        uint256 deadline,
        uint256 _exchange
    ) external payable override returns (uint256) {
        uint256[3] memory amounts =
            _addLiquidityETH(
                _token,
                _to,
                _amountTokenMin,
                _amountETHMin,
                _minAmountOut,
                deadline,
                _exchange
            );

        return amounts[2];
    }

    function addLiquidityETHByPair(
        IUniswapV2Pair _lptoken,
        address _to,
        uint256 _amountTokenMin,
        uint256 _amountETHMin,
        uint256 _minAmountOut,
        uint256 deadline,
        uint256 _exchange
    ) external payable override returns (uint256) {
        uint256[3] memory amounts =
            _addLiquidityETH(
                _getTokenFromPair(IUniswapV2Pair(_lptoken), _exchange),
                _to,
                _amountTokenMin,
                _amountETHMin,
                _minAmountOut,
                deadline,
                _exchange
            );

        return amounts[2];
    }

    function addLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _amountAMin,
        uint256 _amountBMin,
        uint256 _minAmountOutA,
        uint256 _minAmountOutB,
        address _to,
        uint256 _deadline,
        uint256 _exchange
    ) external payable override returns (uint256) {
        uint256[3] memory amounts =
            _addLiquidityByTokens(
                _tokenA,
                _tokenB,
                _amountAMin,
                _amountBMin,
                _minAmountOutA,
                _minAmountOutB,
                _to,
                _deadline,
                _exchange
            );

        return amounts[2];
    }

    function addLiquidityByPair(
        IUniswapV2Pair _lptoken,
        uint256 _amountAMin,
        uint256 _amountBMin,
        uint256 _minAmountOutA,
        uint256 _minAmountOutB,
        address _to,
        uint256 _deadline,
        uint256 _exchange
    ) external payable override returns (uint256) {
        IUniswapV2Pair lptoken = IUniswapV2Pair(_lptoken);
        uint256[3] memory amounts =
            _addLiquidityByTokens(
                lptoken.token0(),
                lptoken.token1(),
                _amountAMin,
                _amountBMin,
                _minAmountOutA,
                _minAmountOutB,
                _to,
                _deadline,
                _exchange
            );
        return amounts[2];
    }

    function withdrawAbandonedAssets(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        if (_token == address(0)) {
            if (_amount == 0) {
                _amount = address(this).balance;
            }
            payable(_to).transfer(_amount);
        } else {
            if (_amount == 0) {
                _amount = IERC20(_token).balanceOf(address(this));
            }
            IERC20(_token).transfer(_to, _amount);
        }
    }

    function removeLiquidityETH(
        address _token,
        uint256 _liquidity,
        uint256 _amountTokenMin,
        uint256 _amountETHMin,
        uint256 _amountOutMin,
        address _to,
        uint256 _deadline,
        uint256 _exchange,
        uint8 _choice
    ) external override returns (uint256[3] memory amounts) {
        amounts = _removeLiquidityETH(
            address(_token),
            _liquidity,
            _amountTokenMin,
            _amountETHMin,
            _amountOutMin,
            _to,
            _deadline,
            _exchange,
            _choice
        );
    }

    function removeLiquidityETHByPair(
        IUniswapV2Pair _lptoken,
        uint256 _liquidity,
        uint256 _amountTokenMin,
        uint256 _amountETHMin,
        uint256 _amountOutMin,
        address _to,
        uint256 _deadline,
        uint256 _exchange,
        uint8 _choice
    ) external override returns (uint256[3] memory amounts) {
        amounts = _removeLiquidityETH(
            address(_getTokenFromPair(IUniswapV2Pair(_lptoken), _exchange)),
            _liquidity,
            _amountTokenMin,
            _amountETHMin,
            _amountOutMin,
            _to,
            _deadline,
            _exchange,
            _choice
        );
    }

    function removeLiquidityETHWithPermit(
        address _token,
        uint256 _liquidity,
        uint256 _amountTokenMin,
        uint256 _amountETHMin,
        uint256 _amountOutMin,
        address _to,
        uint256 _deadline,
        uint256 _exchange,
        uint8 _choice,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override returns (uint256[3] memory amounts) {
        IUniswapV2Pair(
            apis[_exchange].factory.getPair(
                address(apis[_exchange].wethToken),
                _token
            )
        )
            .permit(
            msg.sender,
            address(this),
            _liquidity,
            _deadline,
            _v,
            _r,
            _s
        );

        amounts = _removeLiquidityETH(
            _token,
            _liquidity,
            _amountTokenMin,
            _amountETHMin,
            _amountOutMin,
            _to,
            _deadline,
            _exchange,
            _choice
        );
    }

    function removeLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _liquidity,
        uint256[2] memory _amountMin,
        uint256[2] memory _amountOutMin,
        address _to,
        uint256 _deadline,
        uint256 _exchange,
        uint8 _choice
    ) external override returns (uint256[3] memory amounts) {
        amounts = _removeLiquidity(
            _tokenA,
            _tokenB,
            _liquidity,
            _amountMin,
            _amountOutMin,
            _to,
            _deadline,
            _exchange,
            _choice
        );
    }

    function removeLiquidityByPair(
        IUniswapV2Pair _lptoken,
        uint256 _liquidity,
        uint256[2] memory _amountMin,
        uint256[2] memory _amountOutMin,
        address _to,
        uint256 _deadline,
        uint256 _exchange,
        uint8 _choice
    ) external override returns (uint256[3] memory amounts) {
        amounts = _removeLiquidity(
            _lptoken.token0(),
            _lptoken.token1(),
            _liquidity,
            _amountMin,
            _amountOutMin,
            _to,
            _deadline,
            _exchange,
            _choice
        );
    }

    function removeLiquidityWithPermit(
        address _tokenA,
        address _tokenB,
        uint256 _liquidity,
        uint256[2] memory _amountTokenMin,
        uint256[2] memory _amountOutMin,
        address _to,
        uint256 _deadline,
        uint256 _exchange,
        uint8 _choice,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override returns (uint256[3] memory amounts) {
        IUniswapV2Pair(apis[_exchange].factory.getPair(_tokenA, _tokenB))
            .permit(
            msg.sender,
            address(this),
            _liquidity,
            _deadline,
            _v,
            _r,
            _s
        );

        amounts = _removeLiquidity(
            _tokenA,
            _tokenB,
            _liquidity,
            _amountTokenMin,
            _amountOutMin,
            _to,
            _deadline,
            _exchange,
            _choice
        );
    }

    function _getTokenFromPair(IUniswapV2Pair _lptoken, uint256 _exchange)
        internal
        view
        returns (address token)
    {
        token = _lptoken.token0();
        if (token == address(apis[_exchange].wethToken)) {
            token = _lptoken.token1();
        }
    }

    function _addLiquidityETH(
        address _token,
        address _to,
        uint256 _amountTokenMin,
        uint256 _amountETHMin,
        uint256 _minAmountOut,
        uint256 deadline,
        uint256 _exchange
    ) private returns (uint256[3] memory amounts) {
        amounts = _swapExactETHForTokens(
            msg.value / 2,
            _minAmountOut,
            _token,
            deadline,
            _exchange
        );

        IERC20(_token).approve(address(apis[_exchange].router), amounts[2]);

        (amounts[0], amounts[1], amounts[2]) = apis[_exchange]
            .router
            .addLiquidityETH{value: msg.value / 2}(
            address(_token),
            amounts[2],
            _amountTokenMin,
            _amountETHMin,
            _to,
            deadline
        );

        emit LiquidityAdded(
            _to,
            apis[_exchange].factory.getPair(
                address(apis[_exchange].wethToken),
                _token
            ),
            address(apis[_exchange].wethToken),
            _token,
            _exchange,
            amounts[2],
            amounts[0],
            amounts[1]
        );
    }

    function _addLiquidityByTokens(
        address _tokenA,
        address _tokenB,
        uint256 _amountAMin,
        uint256 _amountBMin,
        uint256 _minAmountOutA,
        uint256 _minAmountOutB,
        address _to,
        uint256 _deadline,
        uint256 _exchange
    ) private returns (uint256[3] memory amounts) {
        uint256[3] memory amountsA;
        amountsA = _swapExactETHForTokens(
            msg.value / 2,
            _minAmountOutA,
            _tokenA,
            _deadline,
            _exchange
        );
        uint256[3] memory amountsB;
        amountsB = _swapExactETHForTokens(
            msg.value / 2,
            _minAmountOutB,
            _tokenB,
            _deadline,
            _exchange
        );
        IERC20(_tokenA).approve(address(apis[_exchange].router), amountsA[2]);
        IERC20(_tokenB).approve(address(apis[_exchange].router), amountsB[2]);
        (amounts[0], amounts[1], amounts[2]) = apis[_exchange]
            .router
            .addLiquidity(
            _tokenA,
            _tokenB,
            amountsA[2],
            amountsB[2],
            _amountAMin,
            _amountBMin,
            _to,
            _deadline
        );

        emit LiquidityAdded(
            _to,
            apis[_exchange].factory.getPair(_tokenA, _tokenB),
            _tokenA,
            _tokenB,
            _exchange,
            amounts[2],
            amounts[0],
            amounts[1]
        );
    }

    function _removeLiquidityETH(
        address _token,
        uint256 _liquidity,
        uint256 _amountTokenMin,
        uint256 _amountETHMin,
        uint256 _amountOutMin,
        address _to,
        uint256 _deadline,
        uint256 _exchange,
        uint8 _choice
    ) private returns (uint256[3] memory amounts) {
        IUniswapV2Pair lpToken =
            IUniswapV2Pair(
                apis[_exchange].factory.getPair(
                    address(apis[_exchange].wethToken),
                    _token
                )
            );

        lpToken.transferFrom(msg.sender, address(this), _liquidity);
        lpToken.approve(address(apis[_exchange].router), _liquidity);

        (amounts[0], amounts[2]) = apis[_exchange].router.removeLiquidityETH(
            _token,
            _liquidity,
            _amountTokenMin,
            _amountETHMin,
            address(this),
            _deadline
        );

        amounts = _checkChoice(
            _token,
            amounts[0],
            address(0),
            0,
            amounts[2],
            _amountOutMin,
            0,
            _to,
            _deadline,
            _exchange,
            _choice
        );

        emit LiquidityRemoved(
            _to,
            address(lpToken),
            address(apis[_exchange].wethToken),
            _token,
            _exchange,
            _liquidity,
            amounts[0],
            amounts[1],
            amounts[2]
        );
    }

    function _removeLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _liquidity,
        uint256[2] memory _amountMin,
        uint256[2] memory _amountOutMin,
        address _to,
        uint256 _deadline,
        uint256 _exchange,
        uint8 _choice
    ) private returns (uint256[3] memory amounts) {
        IUniswapV2Pair lptoken =
            IUniswapV2Pair(apis[_exchange].factory.getPair(_tokenA, _tokenB));

        lptoken.transferFrom(msg.sender, address(this), _liquidity);
        lptoken.approve(address(apis[_exchange].router), _liquidity);

        (amounts[0], amounts[1]) = apis[_exchange].router.removeLiquidity(
            _tokenA,
            _tokenB,
            _liquidity,
            _amountMin[0],
            _amountMin[1],
            address(this),
            _deadline
        );

        amounts = _checkChoice(
            _tokenA,
            amounts[0],
            _tokenB,
            amounts[1],
            0,
            _amountOutMin[0],
            _amountOutMin[1],
            _to,
            _deadline,
            _exchange,
            _choice
        );

        emit LiquidityRemoved(
            _to,
            address(lptoken),
            _tokenA,
            _tokenB,
            _exchange,
            _liquidity,
            amounts[0],
            amounts[1],
            amounts[2]
        );
    }

    function _swapExactETHForTokens(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _token,
        uint256 _deadline,
        uint256 _exchange
    ) internal returns (uint256[3] memory) {
        address[] memory path = new address[](2);
        (path[0], path[1]) = (address(apis[_exchange].wethToken), _token);
        uint256[] memory amounts;
        amounts = apis[_exchange].router.swapExactETHForTokens{
            value: _amountIn
        }(_amountOutMin, path, address(this), _deadline);

        return [amounts[0], 0, amounts[amounts.length - 1]];
    }

    function _swapExactTokensForETH(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _token,
        uint256 _deadline,
        uint256 _exchange
    ) internal returns (uint256[3] memory) {
        address[] memory path = new address[](2);
        (path[0], path[1]) = (_token, address(apis[_exchange].wethToken));

        IERC20(_token).approve(address(apis[_exchange].router), _amountIn);
        uint256[] memory amounts;
        amounts = apis[_exchange].router.swapExactTokensForETH(
            _amountIn,
            _amountOutMin,
            path,
            address(this),
            _deadline
        );

        return [amounts[0], 0, amounts[amounts.length - 1]];
    }

    function _swapExactTokensForTokens(
        address _tokenA,
        address _tokenB,
        uint256 _amountIn,
        uint256 _amountOutMin,
        uint256 _deadline,
        uint256 _exchange
    ) internal returns (uint256[3] memory) {
        address[] memory path = new address[](2);
        (path[0], path[1]) = (_tokenA, _tokenB);
        IERC20(_tokenA).approve(address(apis[_exchange].router), _amountIn);

        uint256[] memory amounts;

        amounts = apis[_exchange].router.swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            path,
            address(this),
            _deadline
        );

        return [_amountIn, amounts[amounts.length - 1], 0];
    }

    function _checkChoice(
        address _tokenA,
        uint256 _amountTokenA,
        address _tokenB,
        uint256 _amountTokenB,
        uint256 _amountETH,
        uint256 _amountOutMinA,
        uint256 _amountOutMinB,
        address _to,
        uint256 _deadline,
        uint256 _exchange,
        uint8 _choice
    ) private returns (uint256[3] memory amounts) {
        if (_choice == 0) {
            //All assets (wethToken pair)
            payable(_to).transfer(_amountETH);
            IERC20(_tokenA).transfer(_to, _amountTokenA);
            return [_amountTokenA, 0, _amountETH];
        }

        if (_choice == 1) {
            //Only ETH (wethToken pair)
            amounts = _swapExactTokensForETH(
                _amountTokenA,
                _amountOutMinA,
                _tokenA,
                _deadline,
                _exchange
            );
            payable(_to).transfer(amounts[2] + _amountETH);
            return [0, 0, amounts[2] + _amountETH];
        }

        if (_choice == 2) {
            // Only token (wethToken pair)
            amounts = _swapExactETHForTokens(
                _amountETH,
                _amountOutMinA,
                _tokenA,
                _deadline,
                _exchange
            );
            IERC20(_tokenA).transfer(_to, _amountTokenA + (amounts[2]));
            return [_amountTokenA + (amounts[2]), 0, 0];
        }

        if (_choice == 3) {
            //All assets (Tokens pair)
            IERC20(_tokenA).transfer(_to, _amountTokenA);
            IERC20(_tokenB).transfer(_to, _amountTokenB);
            return [_amountTokenA, _amountTokenB, 0];
        }

        if (_choice == 4) {
            // Only ETH (Tokens pair)
            amounts = _swapExactTokensForETH(
                _amountTokenB,
                _amountOutMinB,
                _tokenB,
                _deadline,
                _exchange
            );
            _amountETH = amounts[2];
            amounts = _swapExactTokensForETH(
                _amountTokenA,
                _amountOutMinA,
                _tokenA,
                _deadline,
                _exchange
            );
            _amountETH = _amountETH + amounts[2];
            payable(_to).transfer(_amountETH);
            return [0, 0, _amountETH];
        }

        if (_choice == 5) {
            // TokenA and ETH (Tokens pair)
            amounts = _swapExactTokensForETH(
                _amountTokenB,
                _amountOutMinB,
                _tokenB,
                _deadline,
                _exchange
            );
            payable(_to).transfer(amounts[2] + _amountETH);
            IERC20(_tokenA).transfer(_to, _amountTokenA);
            return [_amountTokenA, 0, amounts[2] + _amountETH];
        }

        if (_choice == 6) {
            // TokenB and ETH (Tokens pair)
            amounts = _swapExactTokensForETH(
                _amountTokenA,
                _amountOutMinA,
                _tokenA,
                _deadline,
                _exchange
            );
            payable(_to).transfer(amounts[2] + _amountETH);
            IERC20(_tokenB).transfer(_to, _amountTokenB);
            return [0, _amountTokenB, amounts[2] + _amountETH];
        }

        if (_choice == 7) {
            // Only TokenA (Tokens pair)
            amounts = _swapExactTokensForTokens(
                _tokenB,
                _tokenA,
                _amountTokenB,
                _amountOutMinB,
                _deadline,
                _exchange
            );
            IERC20(_tokenA).transfer(_to, amounts[1] + _amountTokenA);
            return [amounts[1] + _amountTokenA, 0, 0];
        }

        if (_choice == 8) {
            // Only TokenB (Tokens pair)
            amounts = _swapExactTokensForTokens(
                _tokenA,
                _tokenB,
                _amountTokenA,
                _amountOutMinA,
                _deadline,
                _exchange
            );
            IERC20(_tokenB).transfer(_to, amounts[1] + _amountTokenB);
            return [0, amounts[1] + _amountTokenB, 0];
        }
    }
}
