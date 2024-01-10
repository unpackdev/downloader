// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DSMath.sol";
import "./ProtocolWETH.sol";

contract ProtocolUniswapV2 is DSMath, ProtocolWETH {
    address public immutable  router;

    address public constant ethAddr =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor(address _wethAddress, address _uniswapV2RouterAddress)
        ProtocolWETH(_wethAddress)
    {
        router = _uniswapV2RouterAddress;
    }

    event Buy(
        address indexed buyToken,
        address indexed sellToken,
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 getId,
        uint256 setId
    );

    event Sell(
        address indexed buyToken,
        address indexed sellToken,
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 getId,
        uint256 setId
    );

    event AddLiquidity(
        address indexed tokenA,
        address indexed tokenB,
        uint256 amtA,
        uint256 amtB,
        uint256 uniAmount,
        uint256 getId,
        uint256 setId
    );

    event RemoveLiquidity(
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 uniAmount,
        uint256 getId,
        uint256[] setId
    );

    function buyToken(
        address buyAddr,
        address sellAddr,
        uint256 buyAmt,
        uint256 unitAmt
    ) public payable returns (uint256 _sellAmt) {
        uint256 _buyAmt = buyAmt;

        (WethInterface _buyAddr, WethInterface _sellAddr) = changeEthAddress(
            buyAddr,
            sellAddr
        );

        address[] memory paths = getPaths(
            address(_buyAddr),
            address(_sellAddr)
        );

        uint256 _slippageAmt = convert18ToDec(
            _sellAddr.decimals(),
            wmul(unitAmt, convertTo18(_buyAddr.decimals(), _buyAmt))
        );

        checkPair(paths);

        uint256 _expectedAmt = getExpectedSellAmt(paths, _buyAmt);

        require(_slippageAmt >= _expectedAmt, "Too much slippage");

        bool isEth = address(_sellAddr) == wethAddr;

        convertEthToWeth(isEth, _sellAddr, _expectedAmt);

        approve(_sellAddr, address(router), _expectedAmt);

        _sellAmt = IUniswapV2Router02(router).swapTokensForExactTokens(
            _buyAmt,
            _expectedAmt,
            paths,
            address(this),
            block.timestamp + 1
        )[0];

        isEth = address(_buyAddr) == wethAddr;

        convertWethToEth(isEth, _buyAddr, _buyAmt);
    }

    function sellToken(
        address buyAddr,
        address sellAddr,
        uint256 sellAmt,
        uint256 unitAmt
    ) public payable returns (uint256 _buyAmt) {
        uint256 _sellAmt = sellAmt;
        (WethInterface _buyAddr, WethInterface _sellAddr) = changeEthAddress(
            buyAddr,
            sellAddr
        );
        address[] memory paths = getPaths(
            address(_buyAddr),
            address(_sellAddr)
        );

        if (_sellAmt == type(uint256).max) {
            _sellAmt = sellAddr == ethAddr
                ? address(this).balance
                : _sellAddr.balanceOf(address(this));
        }

        uint256 _slippageAmt = convert18ToDec(
            _buyAddr.decimals(),
            wmul(unitAmt, convertTo18(_sellAddr.decimals(), _sellAmt))
        );

        checkPair(paths);
        uint256 _expectedAmt = getExpectedBuyAmt(paths, _sellAmt);
        require(_slippageAmt <= _expectedAmt, "Too much slippage");

        bool isEth = address(_sellAddr) == wethAddr;
        convertEthToWeth(isEth, _sellAddr, _sellAmt);
        approve(_sellAddr, address(router), _sellAmt);

        _buyAmt = IUniswapV2Router02(router).swapExactTokensForTokens(
            _sellAmt,
            _expectedAmt,
            paths,
            address(this),
            block.timestamp + 1
        )[1];

        isEth = address(_buyAddr) == wethAddr;
        convertWethToEth(isEth, _buyAddr, _buyAmt);
    }

    function addTokenLiquidity(
        address tokenA,
        address tokenB,
        uint256 amtA,
        uint256 unitAmt,
        uint256 slippage
    )
        public
        payable
        returns (
            uint256 _amtA,
            uint256 _amtB,
            uint256 _uniAmt
        )
    {
        (_amtA, _amtB, _uniAmt) = _addLiquidity(
            tokenA,
            tokenB,
            amtA,
            unitAmt,
            slippage
        );
    }

    function removeTokenLiquidity(
        address tokenA,
        address tokenB,
        uint256 uniAmt,
        uint256 unitAmtA,
        uint256 unitAmtB
    )
        public
        payable
        returns (
            uint256 _amtA,
            uint256 _amtB,
            uint256 _uniAmt
        )
    {
        (_amtA, _amtB, _uniAmt) = _removeLiquidity(
            tokenA,
            tokenB,
            uniAmt,
            unitAmtA,
            unitAmtB
        );
    }

    function getExpectedBuyAmt(address[] memory paths, uint256 sellAmt)
        internal
        view
        returns (uint256 buyAmt)
    {
        uint256[] memory amts = IUniswapV2Router02(router).getAmountsOut(sellAmt, paths);
        buyAmt = amts[1];
    }

    function getExpectedSellAmt(address[] memory paths, uint256 buyAmt)
        internal
        view
        returns (uint256 sellAmt)
    {
        uint256[] memory amts = IUniswapV2Router02(router).getAmountsIn(buyAmt, paths);
        sellAmt = amts[0];
    }

    function checkPair(address[] memory paths) internal view {
        address pair = IUniswapV2Factory(IUniswapV2Router02(router).factory()).getPair(
            paths[0],
            paths[1]
        );
        require(pair != address(0), "No-exchange-address");
    }

    function getPaths(address buyAddr, address sellAddr)
        internal
        pure
        returns (address[] memory paths)
    {
        paths = new address[](2);
        paths[0] = address(sellAddr);
        paths[1] = address(buyAddr);
    }

    function getMinAmount(
        WethInterface token,
        uint256 amt,
        uint256 slippage
    ) internal view returns (uint256 minAmt) {
        uint256 _amt18 = convertTo18(token.decimals(), amt);
        minAmt = wmul(_amt18, sub(WAD, slippage));
        minAmt = convert18ToDec(token.decimals(), minAmt);
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 _amt,
        uint256 unitAmt,
        uint256 slippage
    )
        internal
        returns (
            uint256 _amtA,
            uint256 _amtB,
            uint256 _liquidity
        )
    {
        (WethInterface _tokenA, WethInterface _tokenB) = changeEthAddress(
            tokenA,
            tokenB
        );

        _amtA = _amt == type(uint256).max
            ? getTokenBal(WethInterface(tokenA))
            : _amt;
        _amtB = convert18ToDec(
            _tokenB.decimals(),
            wmul(unitAmt, convertTo18(_tokenA.decimals(), _amtA))
        );

        bool isEth = address(_tokenA) == wethAddr;
        convertEthToWeth(isEth, _tokenA, _amtA);

        isEth = address(_tokenB) == wethAddr;
        convertEthToWeth(isEth, _tokenB, _amtB);

        approve(_tokenA, address(router), _amtA);
        approve(_tokenB, address(router), _amtB);

        uint256 minAmtA = getMinAmount(_tokenA, _amtA, slippage);
        uint256 minAmtB = getMinAmount(_tokenB, _amtB, slippage);
        (_amtA, _amtB, _liquidity) = IUniswapV2Router02(router).addLiquidity(
            address(_tokenA),
            address(_tokenB),
            _amtA,
            _amtB,
            minAmtA,
            minAmtB,
            address(this),
            block.timestamp + 1
        );
    }

    function _removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 _amt,
        uint256 unitAmtA,
        uint256 unitAmtB
    )
        internal
        returns (
            uint256 _amtA,
            uint256 _amtB,
            uint256 _uniAmt
        )
    {
        WethInterface _tokenA;
        WethInterface _tokenB;
        (_tokenA, _tokenB, _uniAmt) = _getRemoveLiquidityData(
            tokenA,
            tokenB,
            _amt
        );
        {
            uint256 minAmtA = convert18ToDec(
                _tokenA.decimals(),
                wmul(unitAmtA, _uniAmt)
            );
            uint256 minAmtB = convert18ToDec(
                _tokenB.decimals(),
                wmul(unitAmtB, _uniAmt)
            );
            (_amtA, _amtB) = IUniswapV2Router02(router).removeLiquidity(
                address(_tokenA),
                address(_tokenB),
                _uniAmt,
                minAmtA,
                minAmtB,
                address(this),
                block.timestamp + 1
            );
        }

        bool isEth = address(_tokenA) == wethAddr;
        convertWethToEth(isEth, _tokenA, _amtA);

        isEth = address(_tokenB) == wethAddr;
        convertWethToEth(isEth, _tokenB, _amtB);
    }

    function _getRemoveLiquidityData(
        address tokenA,
        address tokenB,
        uint256 _amt
    )
        internal
        returns (
            WethInterface _tokenA,
            WethInterface _tokenB,
            uint256 _uniAmt
        )
    {
        (_tokenA, _tokenB) = changeEthAddress(tokenA, tokenB);
        address exchangeAddr = IUniswapV2Factory(IUniswapV2Router02(router).factory()).getPair(
            address(_tokenA),
            address(_tokenB)
        );
        require(exchangeAddr != address(0), "pair-not-found.");

        WethInterface uniToken = WethInterface(exchangeAddr);
        _uniAmt = _amt == type(uint256).max
            ? uniToken.balanceOf(address(this))
            : _amt;
        approve(uniToken, address(router), _uniAmt);
    }

    function changeEthAddress(address buyAddress, address sellAddress)
        internal
        view
        returns (WethInterface _buy, WethInterface _sell)
    {
        _buy = buyAddress == ethAddr
            ? WethInterface(wethAddr)
            : WethInterface(buyAddress);
        _sell = sellAddress == ethAddr
            ? WethInterface(wethAddr)
            : WethInterface(sellAddress);
    }

    function getTokenBal(WethInterface token)
        internal
        view
        returns (uint256 _amt)
    {
        _amt = address(token) == ethAddr
            ? address(this).balance
            : token.balanceOf(address(this));
    }

    function getSellAmount(
        address buyAddr,
        address sellAddr,
        uint256 buyAmt
    ) external view returns (uint256 amounts) {
        uint256 _buyAmt = buyAmt;
        (WethInterface _buyAddr, WethInterface _sellAddr) = changeEthAddress(
            buyAddr,
            sellAddr
        );
        address[] memory paths = getPaths(
            address(_buyAddr),
            address(_sellAddr)
        );

        checkPair(paths);
        amounts = getExpectedSellAmt(paths, _buyAmt);
    }
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}
