// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeERC20.sol";

interface IWETH {
    function deposit() external payable;
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

interface IBrewlabsLiquidityManager {
    function addLiquidity(
        address token0,
        address token1,
        uint256 _amount0,
        uint256 _amount1,
        uint256 _slipPage
    )
        external
        payable
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );
}

library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

contract BrewlabsZapInConstructor is Ownable {
    using SafeERC20 for IERC20;

    IUniswapV2Factory private constant uniswapFactory =
        IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    IUniswapV2Router02 private constant uniswapRouter =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    IBrewlabsLiquidityManager private constant brewlabsLiquidityManager =
        IBrewlabsLiquidityManager(0xd6A74757F3F307931f94a62331FB4D8884e3cc56);

    address private constant wethTokenAddress =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address private constant ETHAddress =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    uint256 private constant deadline =
        0xf000000000000000000000000000000000000000000000000000000000000000;

    bool public stopped = false;

    uint256 public feeAmount;
    address payable public feeAddress;

    event ZapIn(address sender, address pool, uint256 tokensRec);
    event UpdateFeeAmount(uint256 indexed oldAmount, uint256 indexed newAmount);
    event UpdateFeeAddress(
        address indexed oldAddress,
        address indexed newAddress
    );

    constructor(uint256 _feeAmount, address payable _feeAddress) {
        feeAmount = _feeAmount;
        feeAddress = _feeAddress;
    }

    receive() external payable {
        require(msg.sender != tx.origin, "Do not send ETH directly");
    }

    modifier stopInEmergency() {
        if (stopped) {
            revert("Temporarily Paused");
        } else {
            _;
        }
    }

    function toggleContractActive() public onlyOwner {
        stopped = !stopped;
    }

    function updateFeeAmount(uint256 _feeAmount) external onlyOwner {
        uint256 _oldAmount = feeAmount;
        feeAmount = _feeAmount;
        emit UpdateFeeAmount(_oldAmount, _feeAmount);
    }

    function updateFeeAddress(address payable _feeAddress) external onlyOwner {
        address _oldAddress = feeAddress;
        feeAddress = _feeAddress;
        emit UpdateFeeAddress(_oldAddress, _feeAddress);
    }

    function withdrawTokens(address[] calldata tokens) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == ETHAddress) {
                Address.sendValue(payable(owner()), address(this).balance);
            } else {
                IERC20(tokens[i]).safeTransfer(
                    owner(),
                    IERC20(tokens[i]).balanceOf(address(this))
                );
            }
        }
    }

    function zapIn(address _pairAddress, uint256 _minPoolTokens)
        external
        payable
        stopInEmergency
        returns (uint256)
    {
        require(msg.value > feeAmount, "Zapper: Eth is not enough");
        feeAddress.transfer(feeAmount);

        uint256 toInvest = msg.value - feeAmount;

        uint256 LPBought = _performZapIn(_pairAddress, toInvest);
        require(LPBought >= _minPoolTokens, "High Slippage");

        IERC20(_pairAddress).safeTransfer(msg.sender, LPBought);
        emit ZapIn(msg.sender, _pairAddress, LPBought);

        return LPBought;
    }

    function _performZapIn(address _pairAddress, uint256 _amount)
        internal
        returns (uint256)
    {
        (address _ToUniswapToken0, address _ToUniswapToken1) = _getPairTokens(
            _pairAddress
        );

        IWETH(wethTokenAddress).deposit{value: _amount}();

        _swapIntermediate(
            wethTokenAddress,
            _ToUniswapToken0,
            _ToUniswapToken1,
            _amount
        );

        return
            _uniDeposit(
                _ToUniswapToken0,
                _ToUniswapToken1,
                IERC20(_ToUniswapToken0).balanceOf(address(this)),
                IERC20(_ToUniswapToken1).balanceOf(address(this))
            );
    }

    function _uniDeposit(
        address _ToUnipoolToken0,
        address _ToUnipoolToken1,
        uint256 token0Bought,
        uint256 token1Bought
    ) internal returns (uint256) {
        _approveToken(
            _ToUnipoolToken0,
            address(brewlabsLiquidityManager),
            token0Bought
        );
        _approveToken(
            _ToUnipoolToken1,
            address(brewlabsLiquidityManager),
            token1Bought
        );

        (, , uint256 LP) = brewlabsLiquidityManager.addLiquidity(
            _ToUnipoolToken0,
            _ToUnipoolToken1,
            token0Bought,
            token1Bought,
            9999
        );
        return LP;
    }

    function _swapIntermediate(
        address _toContractAddress,
        address _ToUnipoolToken0,
        address _ToUnipoolToken1,
        uint256 _amount
    ) internal returns (uint256 token0Bought, uint256 token1Bought) {
        IUniswapV2Pair pair = IUniswapV2Pair(
            uniswapFactory.getPair(_ToUnipoolToken0, _ToUnipoolToken1)
        );
        (uint256 res0, uint256 res1, ) = pair.getReserves();
        if (_toContractAddress == _ToUnipoolToken0) {
            uint256 amountToSwap = calculateSwapInAmount(res0, _amount);
            if (amountToSwap <= 0) amountToSwap = _amount / 2;
            token1Bought = _token2Token(
                _toContractAddress,
                _ToUnipoolToken1,
                amountToSwap
            );
            token0Bought = _amount - amountToSwap;
        } else if (_toContractAddress == _ToUnipoolToken1) {
            uint256 amountToSwap = calculateSwapInAmount(res1, _amount);
            if (amountToSwap <= 0) amountToSwap = _amount / 2;
            token0Bought = _token2Token(
                _toContractAddress,
                _ToUnipoolToken0,
                amountToSwap
            );
            token1Bought = _amount - amountToSwap;
        } else {
            uint256 amountToSwap = _amount / 2;
            token0Bought = _token2Token(
                _toContractAddress,
                _ToUnipoolToken0,
                amountToSwap
            );
            token1Bought = _token2Token(
                _toContractAddress,
                _ToUnipoolToken1,
                _amount - amountToSwap
            );
        }
    }

    function _token2Token(
        address _FromTokenContractAddress,
        address _ToTokenContractAddress,
        uint256 tokens2Trade
    ) internal returns (uint256 tokenBought) {
        if (_FromTokenContractAddress == _ToTokenContractAddress) {
            return tokens2Trade;
        }

        _approveToken(
            _FromTokenContractAddress,
            address(uniswapRouter),
            tokens2Trade
        );

        address pair = uniswapFactory.getPair(
            _FromTokenContractAddress,
            _ToTokenContractAddress
        );
        require(pair != address(0), "No Swap Available");
        address[] memory path = new address[](2);
        path[0] = _FromTokenContractAddress;
        path[1] = _ToTokenContractAddress;

        tokenBought = uniswapRouter.swapExactTokensForTokens(
            tokens2Trade,
            1,
            path,
            address(this),
            deadline
        )[path.length - 1];

        require(tokenBought > 0, "Error Swapping Tokens 2");
    }

    function _approveToken(address token, address spender) internal {
        IERC20 _token = IERC20(token);
        if (_token.allowance(address(this), spender) > 0) return;
        else {
            _token.safeApprove(spender, type(uint256).max);
        }
    }

    function _approveToken(
        address token,
        address spender,
        uint256 amount
    ) internal {
        IERC20(token).safeApprove(spender, 0);
        IERC20(token).safeApprove(spender, amount);
    }

    function _getPairTokens(address _pairAddress)
        internal
        view
        returns (address token0, address token1)
    {
        IUniswapV2Pair uniPair = IUniswapV2Pair(_pairAddress);
        token0 = uniPair.token0();
        token1 = uniPair.token1();
    }

    function calculateSwapInAmount(uint256 reserveIn, uint256 userIn)
        internal
        pure
        returns (uint256)
    {
        return
            (Babylonian.sqrt(
                reserveIn * ((userIn * 3988000) + (reserveIn * 3988009))
            ) - (reserveIn * 1997)) / 1994;
    }
}
