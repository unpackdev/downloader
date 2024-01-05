pragma solidity ^0.7.0;

import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IXPriceOracle.sol";
import "./Babylonian.sol";

contract XPoolHandler is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

    IUniswapV2Factory private constant UniSwapV2FactoryAddress =
        IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    IUniswapV2Router02 private constant uniswapRouter =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address private constant wethTokenAddress =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint256 private constant deadline =
        0xf000000000000000000000000000000000000000000000000000000000000000;

    uint256 public totalRaised;
    uint256 public xFitThreeshold;
    uint256 public fundsSplitFactor;

    event INTERNAL_SWAP(address sender, uint256 tokensBought);

    event SWAP_TOKENS(
        address sender,
        uint256 amount,
        address fromToken,
        address toToken
    );
    event POOL_LIQUIDITY(
        address sender,
        address pool,
        address tokenA,
        uint256 amountA,
        address tokenB,
        uint256 amountB
    );
    event REMOVE_LIQUIDITY(
        address sender,
        address pool,
        address tokenA,
        uint256 amountA,
        address tokenB,
        uint256 amountB
    );

    constructor(uint256 _xFitThreeshold, uint256 _fundsSplitFactor) {
        xFitThreeshold = _xFitThreeshold;
        fundsSplitFactor = _fundsSplitFactor;
    }

    /**
    @notice Remove liquidity from a pool
    @param _FromUniPoolAddress The uniswap pair address to reomve liquidity from
    @param _lpTokensAmount The amount of LP
    @return (amountA, amountB) The amount of pair tokens received after removing liquidity
     */
    function redeemLPTokens(
        address _FromUniPoolAddress,
        uint256 _lpTokensAmount
    ) internal nonReentrant returns (uint256, uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(_FromUniPoolAddress);

        require(address(pair) != address(0), "Error: Invalid Unipool Address");

        // get reserves
        address token0 = pair.token0();
        address token1 = pair.token1();

        IERC20(_FromUniPoolAddress).safeApprove(address(uniswapRouter), 0);
        IERC20(_FromUniPoolAddress).safeApprove(
            address(uniswapRouter),
            _lpTokensAmount
        );
        uint256 amountA;
        uint256 amountB;
        if (token0 == wethTokenAddress || token1 == wethTokenAddress) {
            address _token = token0 == wethTokenAddress ? token1 : token0;
            (amountA, amountB) = uniswapRouter.removeLiquidityETH(
                _token,
                _lpTokensAmount,
                1,
                1,
                address(this),
                deadline
            );
            // send tokens
            IERC20(_token).safeTransfer(msg.sender, amountA);
            Address.sendValue(msg.sender, amountB);
        } else {
            (amountA, amountB) = uniswapRouter.removeLiquidity(
                token0,
                token1,
                _lpTokensAmount,
                1,
                1,
                address(this),
                deadline
            );

            // send tokens
            IERC20(token0).safeTransfer(msg.sender, amountA);
            IERC20(token1).safeTransfer(msg.sender, amountB);
        }
        emit REMOVE_LIQUIDITY(
            msg.sender,
            _FromUniPoolAddress,
            token0,
            amountA,
            token1,
            amountB
        );
        return (amountA, amountB);
    }

    /**
    @notice This function is used to invest in given Uniswap V2 pair through either of the tokens
    @param _FromTokenContractAddress The ERC20 token used for investment (address(0x00) if ether)
    @param _pairAddress The Uniswap pair address
    @param _amount The amount of fromToken to invest
    @param _minPoolTokens Reverts if less tokens received than this
    @return Amount of LP bought
     */
    function poolLiquidity(
        address _FromTokenContractAddress,
        address _pairAddress,
        address _xPoolOracle,
        uint256 _amount,
        uint256 _minPoolTokens
    ) internal nonReentrant returns (uint256, uint256) {
        uint256 toInvest = _pullTokens(_FromTokenContractAddress, _amount);
        uint256 LPBought;
        uint256 fundingRaised;
        (address _ToUniswapToken0, address _ToUniswapToken1) =
            _getPairTokens(_pairAddress);

        if (_FromTokenContractAddress == _ToUniswapToken0) {
            (LPBought, fundingRaised) = _poolLiquidityInternal(
                _FromTokenContractAddress,
                _ToUniswapToken1,
                _pairAddress,
                _xPoolOracle,
                toInvest
            );
        } else {
            (LPBought, fundingRaised) = _poolLiquidityInternal(
                _FromTokenContractAddress,
                _ToUniswapToken0,
                _pairAddress,
                _xPoolOracle,
                toInvest
            );
        }

        require(LPBought >= _minPoolTokens, "ERR: High Slippage");

        // Update the price oracle cumulative prices for the pair
        IXPriceOracle(_xPoolOracle).update();

        return (LPBought, fundingRaised);
    }

    function _getPairTokens(address _pairAddress)
        internal
        pure
        returns (address token0, address token1)
    {
        IUniswapV2Pair uniPair = IUniswapV2Pair(_pairAddress);
        token0 = uniPair.token0();
        token1 = uniPair.token1();
    }

    function _pullTokens(address token, uint256 amount)
        internal
        returns (uint256 value)
    {
        if (token == address(0)) {
            require(msg.value > 0, "No eth sent");
            return msg.value;
        }
        require(amount > 0, "Invalid token amount");
        require(msg.value == 0, "Eth sent with token");

        //transfer token
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        return amount;
    }

    // Variables required to compute the dynamic swap amount and paths
    struct TokenSwapVars {
        uint256 amountToSwap;
        uint256 destTokensAmount;
        uint256 fromTokensBought;
        uint256 toTokensBought;
        uint256 destTokenReserve;
        uint256 fundingRaised;
    }

    // This checks if its possible to swap Incoming tokens for XFit from the contract. If its not possible, then uses Uniswap to swap the tokens.
    function _poolLiquidityInternal(
        address _FromTokenContractAddress,
        address _ToTokenContractAddress,
        address _pairAddress,
        address _xPoolOracle,
        uint256 _amount
    ) internal returns (uint256, uint256) {
        TokenSwapVars memory tokenSwapVars;

        tokenSwapVars.amountToSwap = _amount / 2;

        // Convert amountToSwap to equivalent number of XFit tokens by quering prie oracle
        tokenSwapVars.destTokensAmount = IXPriceOracle(_xPoolOracle).consult(
            _FromTokenContractAddress,
            tokenSwapVars.amountToSwap
        );

        // How much of the incoming funds should be used to swap for XFit again
        uint256 splittedFunds =
            _amount.sub(tokenSwapVars.amountToSwap).mul(fundsSplitFactor).div(
                1e18
            );

        // Contract's balance of XFit tokens
        tokenSwapVars.destTokenReserve = IERC20(_ToTokenContractAddress)
            .balanceOf(address(this));

        // If XFit are available in the contract, swap internally
        if (
            tokenSwapVars.destTokenReserve > xFitThreeshold &&
            tokenSwapVars.destTokensAmount <
            (tokenSwapVars.destTokenReserve.sub(xFitThreeshold))
        ) {
            tokenSwapVars.fromTokensBought = tokenSwapVars.amountToSwap;
            tokenSwapVars.toTokensBought = tokenSwapVars.destTokensAmount;
            // Swap the splittedFunds portion of incoming funding to buyBack XFit
            swapSplittedFunds(
                _FromTokenContractAddress,
                _ToTokenContractAddress,
                splittedFunds
            );
            tokenSwapVars.fundingRaised = _amount
                .sub(tokenSwapVars.amountToSwap)
                .sub(splittedFunds);
            totalRaised = totalRaised.add(tokenSwapVars.fundingRaised);
            emit INTERNAL_SWAP(msg.sender, tokenSwapVars.toTokensBought);
        }
        // else use uniswap
        else {
            // divide intermediate into appropriate amount to add liquidity using single side liquidity provision logic descrobed here: https://blog.alphafinance.io/onesideduniswap/
            (
                tokenSwapVars.fromTokensBought,
                tokenSwapVars.toTokensBought
            ) = _swapTokens(
                _FromTokenContractAddress,
                IUniswapV2Pair(_pairAddress),
                _amount
            );
        }

        // Add liquidity to Uniswap
        (uint256 lpAmount, uint256 amountA, uint256 amountB) =
            _uniDeposit(
                _FromTokenContractAddress,
                _ToTokenContractAddress,
                tokenSwapVars.fromTokensBought,
                tokenSwapVars.toTokensBought,
                tokenSwapVars.fundingRaised > 0
            );

        emit POOL_LIQUIDITY(
            msg.sender,
            _pairAddress,
            _FromTokenContractAddress,
            amountA,
            _ToTokenContractAddress,
            amountB
        );

        return (lpAmount, tokenSwapVars.fundingRaised);
    }

    function swapSplittedFunds(
        address _FromTokenContractAddress,
        address _ToTokenContractAddress,
        uint256 _splittedFunds
    ) internal {
        _swapTokensInternal(
            _FromTokenContractAddress,
            _ToTokenContractAddress,
            _splittedFunds
        );
    }

    function _uniDeposit(
        address _ToUnipoolToken0,
        address _ToUnipoolToken1,
        uint256 token0Bought,
        uint256 token1Bought,
        bool isInternalSwap
    )
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        IERC20(_ToUnipoolToken0).safeApprove(address(uniswapRouter), 0);
        IERC20(_ToUnipoolToken1).safeApprove(address(uniswapRouter), 0);

        IERC20(_ToUnipoolToken0).safeApprove(
            address(uniswapRouter),
            token0Bought
        );
        IERC20(_ToUnipoolToken1).safeApprove(
            address(uniswapRouter),
            token1Bought
        );

        (uint256 amountA, uint256 amountB, uint256 LP) =
            uniswapRouter.addLiquidity(
                _ToUnipoolToken0,
                _ToUnipoolToken1,
                token0Bought,
                token1Bought,
                1,
                1,
                address(this),
                deadline
            );

        //Returning Residue in token0, if any.
        if (token0Bought.sub(amountA) > 0) {
            IERC20(_ToUnipoolToken0).safeTransfer(
                msg.sender,
                token0Bought.sub(amountA)
            );
        }

        // Return Xfit residue if there is any only if Uniswap is used for swapping and not the internal reserves.
        if (!isInternalSwap) {
            //Returning Residue in token1, if any

            if (token1Bought.sub(amountB) > 0) {
                IERC20(_ToUnipoolToken1).safeTransfer(
                    msg.sender,
                    token1Bought.sub(amountB)
                );
            }
        }

        return (LP, amountA, amountB);
    }

    function _swapTokens(
        address _fromContractAddress,
        IUniswapV2Pair _pair,
        uint256 _amount
    ) internal returns (uint256 fromTokensBought, uint256 toTokensBought) {
        (address _ToUnipoolToken0, address _ToUnipoolToken1) =
            _getPairTokens(address(_pair));

        (uint256 res0, uint256 res1, ) = _pair.getReserves();

        if (_fromContractAddress == _ToUnipoolToken0) {
            uint256 amountToSwap = calculateSwapInAmount(res0, _amount);
            //if no reserve or a new _pair is created
            if (amountToSwap == 0) amountToSwap = _amount.div(2);
            toTokensBought = _swapTokensInternal(
                _fromContractAddress,
                _ToUnipoolToken1,
                amountToSwap
            );
            fromTokensBought = _amount.sub(amountToSwap);
        } else {
            uint256 amountToSwap = calculateSwapInAmount(res1, _amount);
            //if no reserve or a new _pair is created
            if (amountToSwap == 0) amountToSwap = _amount.div(2);
            toTokensBought = _swapTokensInternal(
                _fromContractAddress,
                _ToUnipoolToken0,
                amountToSwap
            );
            fromTokensBought = _amount.sub(amountToSwap);
        }
    }

    function calculateSwapInAmount(uint256 reserveIn, uint256 userIn)
        internal
        pure
        returns (uint256)
    {
        return
            Babylonian
                .sqrt(
                reserveIn.mul(userIn.mul(3988000) + reserveIn.mul(3988009))
            )
                .sub(reserveIn.mul(1997)) / 1994;
    }

    /**
    @notice This function is used to swap ERC20 <> ERC20
    @param _FromTokenContractAddress The token address to swap from.
    @param _ToTokenContractAddress The token address to swap to. 
    @param tokens2Trade The amount of tokens to swap
    @return tokenBought The quantity of tokens bought
    */
    function _swapTokensInternal(
        address _FromTokenContractAddress,
        address _ToTokenContractAddress,
        uint256 tokens2Trade
    ) internal returns (uint256 tokenBought) {
        if (_FromTokenContractAddress == _ToTokenContractAddress) {
            return tokens2Trade;
        }
        IERC20(_FromTokenContractAddress).safeApprove(
            address(uniswapRouter),
            0
        );
        IERC20(_FromTokenContractAddress).safeApprove(
            address(uniswapRouter),
            tokens2Trade
        );

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
        emit SWAP_TOKENS(
            msg.sender,
            tokens2Trade,
            _FromTokenContractAddress,
            _ToTokenContractAddress
        );
    }

    function getEstimatedLPTokens(
        uint256 _amountIn,
        address _FromTokenContractAddress,
        address _pair
    ) public view returns (uint256 estimatedLps) {
        (uint256 res0, uint256 res1, ) = IUniswapV2Pair(_pair).getReserves();
        (address _ToUnipoolToken0, address _ToUnipoolToken1) =
            _getPairTokens(_pair);
        if (_FromTokenContractAddress == _ToUnipoolToken0) {
            uint256 amountToSwap = calculateSwapInAmount(res0, _amountIn);
            estimatedLps = _amountIn
                .sub(amountToSwap)
                .mul(IUniswapV2Pair(_pair).totalSupply())
                .div(res0);
        } else if (_FromTokenContractAddress == _ToUnipoolToken1) {
            uint256 amountToSwap = calculateSwapInAmount(res1, _amountIn);
            estimatedLps = _amountIn
                .sub(amountToSwap)
                .mul(IUniswapV2Pair(_pair).totalSupply())
                .div(res1);
        }
    }

    // Owner function

    function setXFitThreeshold(uint256 _xFitThreeshold) public onlyOwner {
        xFitThreeshold = _xFitThreeshold;
    }

    function setFundsSplitFactor(uint256 _fundsSplitFactor) public onlyOwner {
        require(_fundsSplitFactor <= 1e18, "Invalid fundsSplitFactor Value");
        fundsSplitFactor = _fundsSplitFactor;
    }
}
