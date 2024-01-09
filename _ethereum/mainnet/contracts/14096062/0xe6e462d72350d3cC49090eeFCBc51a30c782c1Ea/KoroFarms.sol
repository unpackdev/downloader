// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.8;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./AggregatorV3Interface.sol";

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address);
}

interface IUniswapV2Pair {
    function token0() external pure returns (address);

    function token1() external pure returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );
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

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
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

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

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

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

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

abstract contract Zap {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 public immutable koromaru; // Koromaru token
    IERC20 public immutable koromaruUniV2; // Uniswap V2 LP token for Koromaru

    IUniswapV2Factory public immutable UniSwapV2FactoryAddress;
    IUniswapV2Router02 public uniswapRouter;
    address public immutable WETHAddress;

    uint256 private constant swapDeadline =
        0xf000000000000000000000000000000000000000000000000000000000000000;

    struct ZapVariables {
        uint256 LP;
        uint256 koroAmount;
        uint256 wethAmount;
        address tokenToZap;
        uint256 amountToZap;
    }

    event ZappedIn(address indexed account, uint256 amount);
    event ZappedOut(
        address indexed account,
        uint256 amount,
        uint256 koroAmount,
        uint256 Eth
    );

    constructor(
        address _koromaru,
        address _koromaruUniV2,
        address _UniSwapV2FactoryAddress,
        address _uniswapRouter
    ) {
        koromaru = IERC20(_koromaru);
        koromaruUniV2 = IERC20(_koromaruUniV2);

        UniSwapV2FactoryAddress = IUniswapV2Factory(_UniSwapV2FactoryAddress);
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);

        WETHAddress = uniswapRouter.WETH();
    }

    function ZapIn(uint256 _amount, bool _multi)
        internal
        returns (
            uint256 _LP,
            uint256 _WETHBalance,
            uint256 _KoromaruBalance
        )
    {
        (uint256 _koroAmount, uint256 _ethAmount) = _moveTokensToContract(
            _amount
        );
        _approveRouterIfNotApproved();

        (_LP, _WETHBalance, _KoromaruBalance) = !_multi
            ? _zapIn(_koroAmount, _ethAmount)
            : _zapInMulti(_koroAmount, _ethAmount);
        require(_LP > 0, "ZapIn: Invalid LP amount");

        emit ZappedIn(msg.sender, _LP);
    }

    function zapOut(uint256 _koroLPAmount)
        internal
        returns (uint256 _koroTokens, uint256 _ether)
    {
        _approveRouterIfNotApproved();

        uint256 balanceBefore = koromaru.balanceOf(address(this));
        _ether = uniswapRouter.removeLiquidityETHSupportingFeeOnTransferTokens(
            address(koromaru),
            _koroLPAmount,
            1,
            1,
            address(this),
            swapDeadline
        );
        require(_ether > 0, "ZapOut: Eth Output Low");

        uint256 balanceAfter = koromaru.balanceOf(address(this));
        require(balanceAfter > balanceBefore, "ZapOut: Nothing to ZapOut");
        _koroTokens = balanceAfter.sub(balanceBefore);

        emit ZappedOut(msg.sender, _koroLPAmount, _koroTokens, _ether);
    }

    //-------------------- Zap Utils -------------------------
    function _zapIn(uint256 _koroAmount, uint256 _wethAmount)
        internal
        returns (
            uint256 _LP,
            uint256 _WETHBalance,
            uint256 _KoromaruBalance
        )
    {
        ZapVariables memory zapVars;

        zapVars.tokenToZap; // koro or eth
        zapVars.amountToZap; // koro or weth

        (address _Token0, address _Token1) = _getKoroLPPairs(
            address(koromaruUniV2)
        );

        if (_koroAmount > 0 && _wethAmount < 1) {
            // if only koro
            zapVars.amountToZap = _koroAmount;
            zapVars.tokenToZap = address(koromaru);
        } else if (_wethAmount > 0 && _koroAmount < 1) {
            // if only weth
            zapVars.amountToZap = _wethAmount;
            zapVars.tokenToZap = WETHAddress;
        }

        (uint256 token0Out, uint256 token1Out) = _executeSwapForPairs(
            zapVars.tokenToZap,
            _Token0,
            _Token1,
            zapVars.amountToZap
        );

        (_LP, _WETHBalance, _KoromaruBalance) = _toLiquidity(
            _Token0,
            _Token1,
            token0Out,
            token1Out
        );
    }

    function _zapInMulti(uint256 _koroAmount, uint256 _wethAmount)
        internal
        returns (
            uint256 _LPToken,
            uint256 _WETHBalance,
            uint256 _KoromaruBalance
        )
    {
        ZapVariables memory zapVars;

        zapVars.koroAmount = _koroAmount;
        zapVars.wethAmount = _wethAmount;

        zapVars.tokenToZap; // koro or eth
        zapVars.amountToZap; // koro or weth

        {
            (
                uint256 _kLP,
                uint256 _kWETHBalance,
                uint256 _kKoromaruBalance
            ) = _zapIn(zapVars.koroAmount, 0);
            _LPToken += _kLP;
            _WETHBalance += _kWETHBalance;
            _KoromaruBalance += _kKoromaruBalance;
        }
        {
            (
                uint256 _kLP,
                uint256 _kWETHBalance,
                uint256 _kKoromaruBalance
            ) = _zapIn(0, zapVars.wethAmount);
            _LPToken += _kLP;
            _WETHBalance += _kWETHBalance;
            _KoromaruBalance += _kKoromaruBalance;
        }
    }

    function _toLiquidity(
        address _Token0,
        address _Token1,
        uint256 token0Out,
        uint256 token1Out
    )
        internal
        returns (
            uint256 _LP,
            uint256 _WETHBalance,
            uint256 _KoromaruBalance
        )
    {
        _approveToken(_Token0, address(uniswapRouter), token0Out);
        _approveToken(_Token1, address(uniswapRouter), token1Out);

        (uint256 amountA, uint256 amountB, uint256 LP) = uniswapRouter
            .addLiquidity(
                _Token0,
                _Token1,
                token0Out,
                token1Out,
                1,
                1,
                address(this),
                swapDeadline
            );

        _LP = LP;
        _WETHBalance = token0Out.sub(amountA);
        _KoromaruBalance = token1Out.sub(amountB);
    }

    function _approveRouterIfNotApproved() private {
        if (koromaru.allowance(address(this), address(uniswapRouter)) == 0) {
            koromaru.approve(address(uniswapRouter), type(uint256).max);
        }

        if (
            koromaruUniV2.allowance(address(this), address(uniswapRouter)) == 0
        ) {
            koromaruUniV2.approve(address(uniswapRouter), type(uint256).max);
        }
    }

    function _moveTokensToContract(uint256 _amount)
        internal
        returns (uint256 _koroAmount, uint256 _ethAmount)
    {
        _ethAmount = msg.value;

        if (msg.value > 0) IWETH(WETHAddress).deposit{value: _ethAmount}();

        if (msg.value < 1) {
            // ZapIn must have either both Koro and Eth, just Eth or just Koro
            require(_amount > 0, "KOROFARM: Invalid ZapIn Call");
        }

        if (_amount > 0) {
            koromaru.safeTransferFrom(msg.sender, address(this), _amount);
        }

        _koroAmount = _amount;
    }

    function _getKoroLPPairs(address _pairAddress)
        internal
        pure
        returns (address token0, address token1)
    {
        IUniswapV2Pair uniPair = IUniswapV2Pair(_pairAddress);
        token0 = uniPair.token0();
        token1 = uniPair.token1();
    }

    function _executeSwapForPairs(
        address _inToken,
        address _token0,
        address _token1,
        uint256 _amount
    ) internal returns (uint256 _token0Out, uint256 _token1Out) {
        IUniswapV2Pair koroPair = IUniswapV2Pair(address(koromaruUniV2));

        (uint256 resv0, uint256 resv1, ) = koroPair.getReserves();

        if (_inToken == _token0) {
            uint256 swapAmount = determineSwapInAmount(resv0, _amount);
            if (swapAmount < 1) swapAmount = _amount.div(2);
            // swap Weth tokens to koro
            _token1Out = _swapTokenForToken(_inToken, _token1, swapAmount);
            _token0Out = _amount.sub(swapAmount);
        } else {
            uint256 swapAmount = determineSwapInAmount(resv1, _amount);
            if (swapAmount < 1) swapAmount = _amount.div(2);
            _token0Out = _swapTokenForToken(_inToken, _token0, swapAmount);
            _token1Out = _amount.sub(swapAmount);
        }
    }

    function _swapTokenForToken(
        address _swapFrom,
        address _swapTo,
        uint256 _tokensToSwap
    ) internal returns (uint256 tokenBought) {
        if (_swapFrom == _swapTo) {
            return _tokensToSwap;
        }

        _approveToken(
            _swapFrom,
            address(uniswapRouter),
            _tokensToSwap.mul(1e12)
        );

        address pair = UniSwapV2FactoryAddress.getPair(_swapFrom, _swapTo);

        require(pair != address(0), "SwapTokenForToken: Swap path error");
        address[] memory path = new address[](2);
        path[0] = _swapFrom;
        path[1] = _swapTo;

        uint256 balanceBefore = IERC20(_swapTo).balanceOf(address(this));
        uniswapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _tokensToSwap,
            0,
            path,
            address(this),
            swapDeadline
        );
        uint256 balanceAfter = IERC20(_swapTo).balanceOf(address(this));

        tokenBought = balanceAfter.sub(balanceBefore);

        // Ideal, but fails to work with Koromary due to fees
        // tokenBought = uniswapRouter.swapExactTokensForTokens(
        //     _tokensToSwap,
        //     1,
        //     path,
        //     address(this),
        //     swapDeadline
        // )[path.length - 1];
        // }

        require(tokenBought > 0, "SwapTokenForToken: Error Swapping Tokens 2");
    }

    function determineSwapInAmount(uint256 _pairResIn, uint256 _userAmountIn)
        internal
        pure
        returns (uint256)
    {
        return
            (_sqrt(
                _pairResIn *
                    ((_userAmountIn * 3988000) + (_pairResIn * 3988009))
            ) - (_pairResIn * 1997)) / 1994;
    }

    function _sqrt(uint256 _val) internal pure returns (uint256 z) {
        if (_val > 3) {
            z = _val;
            uint256 x = _val / 2 + 1;
            while (x < z) {
                z = x;
                x = (_val / x + x) / 2;
            }
        } else if (_val != 0) {
            z = 1;
        }
    }

    function _approveToken(
        address token,
        address spender,
        uint256 amount
    ) internal {
        IERC20 _token = IERC20(token);
        _token.safeApprove(spender, 0);
        _token.safeApprove(spender, amount);
    }

    //---------------- End of Zap Utils ----------------------
}

contract KoroFarms is Ownable, Pausable, ReentrancyGuard, Zap {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct UserInfo {
        uint256 amount;
        uint256 koroDebt;
        uint256 ethDebt;
        uint256 unpaidKoro;
        uint256 unpaidEth;
        uint256 lastRewardHarvestedTime;
    }

    struct FarmInfo {
        uint256 accKoroRewardsPerShare;
        uint256 accEthRewardsPerShare;
        uint256 lastRewardTimestamp;
    }

    AggregatorV3Interface internal priceFeed;
    uint256 internal immutable koromaruDecimals;
    uint256 internal constant EthPriceFeedDecimal = 1e8;
    uint256 internal constant precisionScaleUp = 1e30;
    uint256 internal constant secsPerDay = 1 days / 1 seconds;
    uint256 private taxRefundPercentage;
    uint256 internal constant _1hundred_Percent = 10000;
    uint256 public APR; // 100% = 10000, 50% = 5000, 15% = 1500
    uint256 rewardHarvestingInterval;
    uint256 public koroRewardAllocation;
    uint256 public ethRewardAllocation;
    uint256 internal maxLPLimit;
    uint256 internal zapKoroLimit;

    FarmInfo public farmInfo;
    mapping(address => UserInfo) public userInfo;

    uint256 public totalEthRewarded; // total amount of eth given as rewards
    uint256 public totalKoroRewarded; // total amount of Koro given as rewards

    //---------------- Contract Events -------------------

    event Compound(address indexed account, uint256 koro, uint256 eth);
    event Withdraw(address indexed account, uint256 amount);
    event Deposit(address indexed account, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event KoroRewardsHarvested(address indexed account, uint256 Kororewards);
    event EthRewardsHarvested(address indexed account, uint256 Ethrewards);
    event APRUpdated(uint256 OldAPR, uint256 NewAPR);
    event Paused();
    event Unpaused();
    event IncreaseKoroRewardPool(uint256 amount);
    event IncreaseEthRewardPool(uint256 amount);

    //------------- End of Contract Events ----------------

    constructor(
        address _koromaru,
        address _koromaruUniV2,
        address _UniSwapV2FactoryAddress,
        address _uniswapRouter,
        uint256 _apr,
        uint256 _taxToRefund,
        uint256 _koromaruTokenDecimals,
        uint256 _koroRewardAllocation,
        uint256 _rewardHarvestingInterval,
        uint256 _zapKoroLimit
    ) Zap(_koromaru, _koromaruUniV2, _UniSwapV2FactoryAddress, _uniswapRouter) {
        require(
            _koroRewardAllocation <= 10000,
            "setRewardAllocations: Invalid rewards allocation"
        );
        require(_apr <= 10000, "SetDailyAPR: Invalid APR Value");

        approveRouterIfNotApproved();

        koromaruDecimals = 10**_koromaruTokenDecimals;
        zapKoroLimit = _zapKoroLimit * 10**_koromaruTokenDecimals;
        APR = _apr;
        koroRewardAllocation = _koroRewardAllocation;
        ethRewardAllocation = _1hundred_Percent.sub(_koroRewardAllocation);
        taxRefundPercentage = _taxToRefund;

        farmInfo = FarmInfo({
            lastRewardTimestamp: block.timestamp,
            accKoroRewardsPerShare: 0,
            accEthRewardsPerShare: 0
        });

        rewardHarvestingInterval = _rewardHarvestingInterval * 1 seconds;
        priceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
    }

    //---------------- Contract Owner  ----------------------
    /**
     * @notice Update chainLink Eth Price feed
     */
    function updatePriceFeed(address _usdt_eth_aggregator) external onlyOwner {
        priceFeed = AggregatorV3Interface(_usdt_eth_aggregator);
    }

    /**
     * @notice Set's tax refund percentage for Koromaru
     * @dev User 100% = 10000, 50% = 5000, 15% = 1500 etc.
     */
    function setTaxRefundPercent(uint256 _taxToRefund) external onlyOwner {
        taxRefundPercentage = _taxToRefund;
    }

    /**
     * @notice Set's max koromaru per transaction
     * @dev Decimals will be added automatically
     */
    function setZapLimit(uint256 _limit) external onlyOwner {
        zapKoroLimit = _limit * koromaruDecimals;
    }

    /**
     * @notice Set's daily ROI percentage for the farm
     * @dev User 100% = 10000, 50% = 5000, 15% = 1500 etc.
     */
    function setDailyAPR(uint256 _dailyAPR) external onlyOwner {
        updateFarm();
        require(_dailyAPR <= 10000, "SetDailyAPR: Invalid APR Value");
        uint256 oldAPr = APR;
        APR = _dailyAPR;
        emit APRUpdated(oldAPr, APR);
    }

    /**
     * @notice Set's reward allocation for reward pool
     * @dev Set for Koromaru only, eth's allocation will be calcuated. User 100% = 10000, 50% = 5000, 15% = 1500 etc.
     */
    function setRewardAllocations(uint256 _koroAllocation) external onlyOwner {
        // setting 10000 (100%) will set eth rewards to 0.
        require(
            _koroAllocation <= 10000,
            "setRewardAllocations: Invalid rewards allocation"
        );
        koroRewardAllocation = _koroAllocation;
        ethRewardAllocation = _1hundred_Percent.sub(_koroAllocation);
    }

    /**
     * @notice Set's maximum amount of LPs that can be staked in this farm
     * @dev When 0, no limit is imposed. When max is reached farmers cannot stake more LPs or compound.
     */
    function setMaxLPLimit(uint256 _maxLPLimit) external onlyOwner {
        // A new user’s stake cannot cause the amount of LP tokens in the farm to exceed this value
        // MaxLP can be set to 0(nomax)
        maxLPLimit = _maxLPLimit;
    }

    /**
     * @notice Reset's the chainLink price feed to the default price feed
     */
    function resetPriceFeed() external onlyOwner {
        priceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
    }

    /**
     * @notice Withdraw foreign tokens sent to this contract
     * @dev Can only withdraw none koromaru tokens and KoroV2 tokens
     */
    function withdrawForeignToken(address _token)
        external
        nonReentrant
        onlyOwner
    {
        require(_token != address(0), "KOROFARM: Invalid Token");
        require(
            _token != address(koromaru),
            "KOROFARM: Token cannot be same as koromaru tokens"
        );
        require(
            _token != address(koromaruUniV2),
            "KOROFARM: Token cannot be same as farmed tokens"
        );

        uint256 amount = IERC20(_token).balanceOf(address(this));
        if (amount > 0) {
            IERC20(_token).safeTransfer(msg.sender, amount);
        }
    }

    /**
     * @notice Deposit Koromaru tokens into reward pool
     */
    function depositKoroRewards(uint256 _amount)
        external
        onlyOwner
        nonReentrant
    {
        require(_amount > 0, "KOROFARM: Invalid Koro Amount");

        koromaru.safeTransferFrom(msg.sender, address(this), _amount);
        emit IncreaseKoroRewardPool(_amount);
    }

    /**
     * @notice Deposit Eth tokens into reward pool
     */
    function depositEthRewards() external payable onlyOwner nonReentrant {
        require(msg.value > 0, "KOROFARM: Invalid Eth Amount");
        emit IncreaseEthRewardPool(msg.value);
    }

    /**
     * @notice This function will pause the farm and withdraw all rewards in case of failure or emergency
     */
    function pauseAndRemoveRewardPools() external onlyOwner whenNotPaused {
        // only to be used by admin in critical situations
        uint256 koroBalance = koromaru.balanceOf(address(this));
        uint256 ethBalance = payable(address(this)).balance;
        if (koroBalance > 0) {
            koromaru.safeTransfer(msg.sender, koroBalance);
        }

        if (ethBalance > 0) {
            (bool sent, ) = payable(msg.sender).call{value: ethBalance}("");
            require(sent, "Failed to send Ether");
        }
    }

    /**
     * @notice Initiate stopped state
     * @dev Only possible when contract not paused.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
        emit Paused();
    }

    /**
     * @notice Initiate normal state
     * @dev Only possible when contract is paused.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
        emit Unpaused();
    }

    //-------------- End Contract Owner  --------------------

    //---------------- Contract Farmer  ----------------------
    /**
     * @notice Calculates and returns pending rewards for a farmer
     */
    function getPendingRewards(address _farmer)
        public
        view
        returns (uint256 pendinKoroTokens, uint256 pendingEthWei)
    {
        UserInfo storage user = userInfo[_farmer];
        uint256 accKoroRewardsPerShare = farmInfo.accKoroRewardsPerShare;
        uint256 accEthRewardsPerShare = farmInfo.accEthRewardsPerShare;
        uint256 stakedTVL = getStakedTVL();

        if (block.timestamp > farmInfo.lastRewardTimestamp && stakedTVL != 0) {
            uint256 timeElapsed = block.timestamp.sub(
                farmInfo.lastRewardTimestamp
            );
            uint256 koroReward = timeElapsed.mul(
                getNumberOfKoroRewardsPerSecond(koroRewardAllocation)
            );
            uint256 ethReward = timeElapsed.mul(
                getAmountOfEthRewardsPerSecond(ethRewardAllocation)
            );

            accKoroRewardsPerShare = accKoroRewardsPerShare.add(
                koroReward.mul(precisionScaleUp).div(stakedTVL)
            );
            accEthRewardsPerShare = accEthRewardsPerShare.add(
                ethReward.mul(precisionScaleUp).div(stakedTVL)
            );
        }

        pendinKoroTokens = user
            .amount
            .mul(accKoroRewardsPerShare)
            .div(precisionScaleUp)
            .sub(user.koroDebt)
            .add(user.unpaidKoro);

        pendingEthWei = user
            .amount
            .mul(accEthRewardsPerShare)
            .div(precisionScaleUp)
            .sub(user.ethDebt)
            .add(user.unpaidEth);
    }

    /**
     * @notice Calculates and returns the TVL in USD staked in the farm
     * @dev Uses the price of 1 Koromaru to calculate the TVL in USD
     */
    function getStakedTVL() public view returns (uint256) {
        uint256 stakedLP = koromaruUniV2.balanceOf(address(this));
        uint256 totalLPsupply = koromaruUniV2.totalSupply();
        return stakedLP.mul(getTVLUsingKoro()).div(totalLPsupply);
    }

    /**
     * @notice Calculates and updates the farm's rewards per share
     * @dev Called by other function to update the function state
     */
    function updateFarm() public whenNotPaused returns (FarmInfo memory farm) {
        farm = farmInfo;

        uint256 WETHBalance = IERC20(WETHAddress).balanceOf(address(this));
        if (WETHBalance > 0) IWETH(WETHAddress).withdraw(WETHBalance);

        if (block.timestamp > farm.lastRewardTimestamp) {
            uint256 stakedTVL = getStakedTVL();

            if (stakedTVL > 0) {
                uint256 timeElapsed = block.timestamp.sub(
                    farm.lastRewardTimestamp
                );
                uint256 koroReward = timeElapsed.mul(
                    getNumberOfKoroRewardsPerSecond(koroRewardAllocation)
                );
                uint256 ethReward = timeElapsed.mul(
                    getAmountOfEthRewardsPerSecond(ethRewardAllocation)
                );
                farm.accKoroRewardsPerShare = farm.accKoroRewardsPerShare.add(
                    (koroReward.mul(precisionScaleUp) / stakedTVL)
                );
                farm.accEthRewardsPerShare = farm.accEthRewardsPerShare.add(
                    (ethReward.mul(precisionScaleUp) / stakedTVL)
                );
            }

            farm.lastRewardTimestamp = block.timestamp;
            farmInfo = farm;
        }
    }

    /**
     * @notice Deposit Koromaru tokens into farm
     * @dev Deposited Koromaru will zap into Koro/WETH LP tokens, a refund of TX fee % will be issued
     */
    function depositKoroTokensOnly(uint256 _amount)
        external
        whenNotPaused
        nonReentrant
    {
        require(_amount > 0, "KOROFARM: Invalid Koro Amount");
        require(
            _amount <= zapKoroLimit,
            "KOROFARM: Can't deposit more than Zap Limit"
        );

        (uint256 lpZappedIn, , ) = ZapIn(_amount, false);

        // do tax refund
        userInfo[msg.sender].unpaidKoro += _amount.mul(taxRefundPercentage).div(
            _1hundred_Percent
        );

        onDeposit(msg.sender, lpZappedIn);
    }

    /**
     * @notice Deposit Koro/WETH LP tokens into farm
     */
    function depositKoroLPTokensOnly(uint256 _amount)
        external
        whenNotPaused
        nonReentrant
    {
        require(_amount > 0, "KOROFARM: Invalid KoroLP Amount");
        koromaruUniV2.safeTransferFrom(msg.sender, address(this), _amount);
        onDeposit(msg.sender, _amount);
    }

    /**
     * @notice Deposit Koromaru, Koromaru/Eth LP and Eth at once into farm requires all 3
     */
    function depositMultipleAssets(uint256 _koro, uint256 _koroLp)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        // require(_koro > 0, "KOROFARM: Invalid Koro Amount");
        // require(_koroLp > 0, "KOROFARM: Invalid LP Amount");
        require(
            _koro <= zapKoroLimit,
            "KOROFARM: Can't deposit more than Zap Limit"
        );

        // execute the zap
        // (uint256 lpZappedIn,uint256 wethBalance, uint256 korobalance)= ZapIn(_koro, true);
        (uint256 lpZappedIn, , ) = msg.value > 0
            ? ZapIn(_koro, true)
            : ZapIn(_koro, false);

        // transfer the lp in
        if (_koroLp > 0)
            koromaruUniV2.safeTransferFrom(
                address(msg.sender),
                address(this),
                _koroLp
            );

        uint256 sumOfLps = lpZappedIn + _koroLp;

        // do tax refund
        userInfo[msg.sender].unpaidKoro += _koro.mul(taxRefundPercentage).div(
            _1hundred_Percent
        );

        onDeposit(msg.sender, sumOfLps);
    }

    /**
     * @notice Deposit Eth only into farm
     * @dev Deposited Eth will zap into Koro/WETH LP tokens
     */
    function depositEthOnly() external payable whenNotPaused nonReentrant {
        require(msg.value > 0, "KOROFARM: Invalid Eth Amount");

        // (uint256 lpZappedIn, uint256 wethBalance, uint256 korobalance)= ZapIn(0, false);
        (uint256 lpZappedIn, , ) = ZapIn(0, false);

        onDeposit(msg.sender, lpZappedIn);
    }

    /**
     * @notice Withdraw all staked LP tokens + rewards from farm. Only possilbe after harvest interval.
      Use emergency withdraw if you want to withdraw before harvest interval. No rewards will be returned.
     * @dev Farmer's can choose to get back LP tokens or Zap out to get Koromaru and Eth
     */
    function withdraw(bool _useZapOut) external whenNotPaused nonReentrant {
        uint256 balance = userInfo[msg.sender].amount;
        require(balance > 0, "Withdraw: You have no balance");
        updateFarm();

        if (_useZapOut) {
            zapLPOut(balance);
        } else {
            koromaruUniV2.transfer(msg.sender, balance);
        }

        onWithdraw(msg.sender);
        emit Withdraw(msg.sender, balance);
    }

    /**
     * @notice Harvest all rewards from farm
     */
    function harvest() external whenNotPaused nonReentrant {
        updateFarm();
        harvestRewards(msg.sender);
    }

    /**
     * @notice Compounds rewards from farm. Only available after harvest interval is reached for farmer.
     */
    function compound() external whenNotPaused nonReentrant {
        updateFarm();
        UserInfo storage user = userInfo[msg.sender];
        require(
            block.timestamp - user.lastRewardHarvestedTime >=
                rewardHarvestingInterval,
            "HarvestRewards: Not yet ripe"
        );

        uint256 koroCompounded;
        uint256 ethCompounded;

        uint256 pendinKoroTokens = user
            .amount
            .mul(farmInfo.accKoroRewardsPerShare)
            .div(precisionScaleUp)
            .sub(user.koroDebt)
            .add(user.unpaidKoro);

        uint256 pendingEthWei = user
            .amount
            .mul(farmInfo.accEthRewardsPerShare)
            .div(precisionScaleUp)
            .sub(user.ethDebt)
            .add(user.unpaidEth);
        {
            uint256 koromaruBalance = koromaru.balanceOf(address(this));
            if (pendinKoroTokens > 0) {
                if (pendinKoroTokens > koromaruBalance) {
                    // not enough koro balance to reward farmer
                    user.unpaidKoro = pendinKoroTokens.sub(koromaruBalance);
                    totalKoroRewarded = totalKoroRewarded.add(koromaruBalance);
                    koroCompounded = koromaruBalance;
                } else {
                    user.unpaidKoro = 0;
                    totalKoroRewarded = totalKoroRewarded.add(pendinKoroTokens);
                    koroCompounded = pendinKoroTokens;
                }
            }
        }

        {
            uint256 ethBalance = getEthBalance();
            if (pendingEthWei > ethBalance) {
                // not enough Eth balance to reward farmer
                user.unpaidEth = pendingEthWei.sub(ethBalance);
                totalEthRewarded = totalEthRewarded.add(ethBalance);
                IWETH(WETHAddress).deposit{value: ethBalance}();
                ethCompounded = ethBalance;
            } else {
                user.unpaidEth = 0;
                totalEthRewarded = totalEthRewarded.add(pendingEthWei);
                IWETH(WETHAddress).deposit{value: pendingEthWei}();
                ethCompounded = pendingEthWei;
            }
        }
        (uint256 LP, , ) = _zapInMulti(koroCompounded, ethCompounded);

        onCompound(msg.sender, LP);
        emit Compound(msg.sender, koroCompounded, ethCompounded);
    }

    /**
     * @notice Returns time in seconds to next harvest.
     */
    function timeToHarvest(address _user)
        public
        view
        whenNotPaused
        returns (uint256)
    {
        UserInfo storage user = userInfo[_user];
        if (
            block.timestamp - user.lastRewardHarvestedTime >=
            rewardHarvestingInterval
        ) {
            return 0;
        }
        return
            user.lastRewardHarvestedTime.sub(
                block.timestamp.sub(rewardHarvestingInterval)
            );
    }

    /**
     * @notice Withdraw all staked LP tokens without rewards.
     */
    function emergencyWithdraw() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        koromaruUniV2.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, user.amount);

        userInfo[msg.sender] = UserInfo(0, 0, 0, 0, 0, 0);
    }

    //--------------- End Contract Farmer  -------------------

    //---------------- Contract Utils  ----------------------

    /**
     * @notice Calculates the total amount of rewards per day in USD
     * @dev The returned value is in USD * 1e18 (WETH decimals), actual USD value is calculated by dividing the value by 1e18
     */
    function getUSDDailyRewards() public view whenNotPaused returns (uint256) {
        uint256 stakedLP = koromaruUniV2.balanceOf(address(this));
        uint256 totalLPsupply = koromaruUniV2.totalSupply();
        uint256 stakedTVL = stakedLP.mul(getTVLUsingKoro()).div(totalLPsupply);
        return APR.mul(stakedTVL).div(_1hundred_Percent);
    }

    /**
     * @notice Calculates the total amount of rewards per second in USD
     * @dev The returned value is in USD * 1e18 (WETH decimals), actual USD value is calculated by dividing the value by 1e18
     */
    function getUSDRewardsPerSecond() internal view returns (uint256) {
        // final return value should be divided by (1e18) (i.e WETH decimals) to get USD value
        uint256 dailyRewards = getUSDDailyRewards();
        return dailyRewards.div(secsPerDay);
    }

    /**
     * @notice Calculates the total number of koromaru token rewards per second
     * @dev The returned value must be divided by the koromaru token decimals to get the actual value
     */
    function getNumberOfKoroRewardsPerSecond(uint256 _koroRewardAllocation)
        internal
        view
        returns (uint256)
    {
        uint256 priceOfUintKoro = getLatestKoroPrice(); // 1e18
        uint256 rewardsPerSecond = getUSDRewardsPerSecond(); // 1e18

        return
            rewardsPerSecond
                .mul(_koroRewardAllocation)
                .mul(koromaruDecimals)
                .div(priceOfUintKoro)
                .div(_1hundred_Percent); //to be div by koro decimals (i.e 1**(18-18+korodecimals)
    }

    /**
     * @notice Calculates the total amount of Eth rewards per second
     * @dev The returned value must be divided by the 1e18 to get the actual value
     */
    function getAmountOfEthRewardsPerSecond(uint256 _ethRewardAllocation)
        internal
        view
        returns (uint256)
    {
        uint256 priceOfUintEth = getLatestEthPrice(); // 1e8
        uint256 rewardsPerSecond = getUSDRewardsPerSecond(); // 1e18
        uint256 scaleUpToWei = 1e8;

        return
            rewardsPerSecond
                .mul(_ethRewardAllocation)
                .mul(scaleUpToWei)
                .div(priceOfUintEth)
                .div(_1hundred_Percent); // to be div by 1e18 (i.e 1**(18-8+8)
    }

    /**
     * @notice Returns the rewards rate/second for both koromaru and eth
     */
    function getRewardsPerSecond()
        public
        view
        whenNotPaused
        returns (uint256 koroRewards, uint256 ethRewards)
    {
        require(
            koroRewardAllocation.add(ethRewardAllocation) == _1hundred_Percent,
            "getRewardsPerSecond: Invalid reward allocation ratio"
        );

        koroRewards = getNumberOfKoroRewardsPerSecond(koroRewardAllocation);
        ethRewards = getAmountOfEthRewardsPerSecond(ethRewardAllocation);
    }

    /**
     * @notice Calculates and returns the TVL in USD (actaul TVL, not staked TVL)
     * @dev Uses Eth price from price feed to calculate the TVL in USD
     */
    function getTVL() public view returns (uint256 tvl) {
        // final return value should be divided by (1e18) (i.e WETH decimals) to get USD value
        IUniswapV2Pair koroPair = IUniswapV2Pair(address(koromaruUniV2));
        address token0 = koroPair.token0();
        (uint256 resv0, uint256 resv1, ) = koroPair.getReserves();
        uint256 TVLEth = 2 *
            (address(token0) == address(koromaru) ? resv1 : resv0);
        uint256 priceOfEth = getLatestEthPrice();

        tvl = TVLEth.mul(priceOfEth).div(EthPriceFeedDecimal);
    }

    /**
     * @notice Calculates and returns the TVL in USD (actaul TVL, not staked TVL)
     * @dev Uses minimum Eth price in USD for 1 koromaru token to calculate the TVL in USD
     */
    function getTVLUsingKoro() public view whenNotPaused returns (uint256 tvl) {
        // returned value should be divided by (1e18) (i.e WETH decimals) to get USD value
        IUniswapV2Pair koroPair = IUniswapV2Pair(address(koromaruUniV2));
        address token0 = koroPair.token0();
        (uint256 resv0, uint256 resv1, ) = koroPair.getReserves();
        uint256 TVLKoro = 2 *
            (address(token0) == address(koromaru) ? resv0 : resv1);
        uint256 priceOfKoro = getLatestKoroPrice();

        tvl = TVLKoro.mul(priceOfKoro).div(koromaruDecimals);
    }

    /**
     * @notice Get's the latest Eth price in USD
     * @dev Uses ChainLink price feed to get the latest Eth price in USD
     */
    function getLatestEthPrice() internal view returns (uint256) {
        // final return value should be divided by 1e8 to get USD value
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    /**
     * @notice Get's the latest Unit Koro price in USD
     * @dev Uses estimated price per koromaru token in USD
     */
    function getLatestKoroPrice() internal view returns (uint256) {
        // returned value must be divided by 1e18 (i.e WETH decimals) to get USD value
        IUniswapV2Pair koroPair = IUniswapV2Pair(address(koromaruUniV2));
        address token0 = koroPair.token0();
        bool isKoro = address(token0) == address(koromaru);

        (uint256 resv0, uint256 resv1, ) = koroPair.getReserves();
        uint256 oneKoro = 1 * koromaruDecimals;

        uint256 optimalWethAmount = uniswapRouter.getAmountOut(
            oneKoro,
            isKoro ? resv0 : resv1,
            isKoro ? resv1 : resv0
        ); //uniswapRouter.quote(oneKoro, isKoro ? resv1 : resv0, isKoro ? resv0 : resv1);
        uint256 priceOfEth = getLatestEthPrice();

        return optimalWethAmount.mul(priceOfEth).div(EthPriceFeedDecimal);
    }

    function onDeposit(address _user, uint256 _amount) internal {
        require(!reachedMaxLimit(), "KOROFARM: Farm is full");
        UserInfo storage user = userInfo[_user];
        updateFarm();

        if (user.amount > 0) {
            // record as unpaid
            user.unpaidKoro = user
                .amount
                .mul(farmInfo.accKoroRewardsPerShare)
                .div(precisionScaleUp)
                .sub(user.koroDebt)
                .add(user.unpaidKoro);

            user.unpaidEth = user
                .amount
                .mul(farmInfo.accEthRewardsPerShare)
                .div(precisionScaleUp)
                .sub(user.ethDebt)
                .add(user.unpaidEth);
        }

        user.amount = user.amount.add(_amount);
        user.koroDebt = user.amount.mul(farmInfo.accKoroRewardsPerShare).div(
            precisionScaleUp
        );
        user.ethDebt = user.amount.mul(farmInfo.accEthRewardsPerShare).div(
            precisionScaleUp
        );

        if (
            (block.timestamp - user.lastRewardHarvestedTime >=
                rewardHarvestingInterval) || (rewardHarvestingInterval == 0)
        ) {
            user.lastRewardHarvestedTime = block.timestamp;
        }

        emit Deposit(_user, _amount);
    }

    function onWithdraw(address _user) internal {
        harvestRewards(_user);
        userInfo[msg.sender].amount = 0;

        userInfo[msg.sender].koroDebt = 0;
        userInfo[msg.sender].ethDebt = 0;
    }

    function onCompound(address _user, uint256 _amount) internal {
        require(!reachedMaxLimit(), "KOROFARM: Farm is full");
        UserInfo storage user = userInfo[_user];

        user.amount = user.amount.add(_amount);
        user.koroDebt = user.amount.mul(farmInfo.accKoroRewardsPerShare).div(
            precisionScaleUp
        );
        user.ethDebt = user.amount.mul(farmInfo.accEthRewardsPerShare).div(
            precisionScaleUp
        );

        user.lastRewardHarvestedTime = block.timestamp;
    }

    function harvestRewards(address _user) internal {
        UserInfo storage user = userInfo[_user];
        require(
            block.timestamp - user.lastRewardHarvestedTime >=
                rewardHarvestingInterval,
            "HarvestRewards: Not yet ripe"
        );

        uint256 pendinKoroTokens = user
            .amount
            .mul(farmInfo.accKoroRewardsPerShare)
            .div(precisionScaleUp)
            .sub(user.koroDebt)
            .add(user.unpaidKoro);

        uint256 pendingEthWei = user
            .amount
            .mul(farmInfo.accEthRewardsPerShare)
            .div(precisionScaleUp)
            .sub(user.ethDebt)
            .add(user.unpaidEth);

        {
            uint256 koromaruBalance = koromaru.balanceOf(address(this));
            if (pendinKoroTokens > 0) {
                if (pendinKoroTokens > koromaruBalance) {
                    // not enough koro balance to reward farmer
                    koromaru.safeTransfer(_user, koromaruBalance);
                    user.unpaidKoro = pendinKoroTokens.sub(koromaruBalance);
                    totalKoroRewarded = totalKoroRewarded.add(koromaruBalance);
                    emit KoroRewardsHarvested(_user, koromaruBalance);
                } else {
                    koromaru.safeTransfer(_user, pendinKoroTokens);
                    user.unpaidKoro = 0;
                    totalKoroRewarded = totalKoroRewarded.add(pendinKoroTokens);
                    emit KoroRewardsHarvested(_user, pendinKoroTokens);
                }
            }
        }
        {
            uint256 ethBalance = getEthBalance();
            if (pendingEthWei > ethBalance) {
                // not enough Eth balance to reward farmer
                (bool sent, ) = _user.call{value: ethBalance}("");
                require(sent, "Failed to send Ether");
                user.unpaidEth = pendingEthWei.sub(ethBalance);
                totalEthRewarded = totalEthRewarded.add(ethBalance);
                emit EthRewardsHarvested(_user, ethBalance);
            } else {
                (bool sent, ) = _user.call{value: pendingEthWei}("");
                require(sent, "Failed to send Ether");
                user.unpaidEth = 0;
                totalEthRewarded = totalEthRewarded.add(pendingEthWei);
                emit EthRewardsHarvested(_user, pendingEthWei);
            }
        }
        user.koroDebt = user.amount.mul(farmInfo.accKoroRewardsPerShare).div(
            precisionScaleUp
        );
        user.ethDebt = user.amount.mul(farmInfo.accEthRewardsPerShare).div(
            precisionScaleUp
        );
        user.lastRewardHarvestedTime = block.timestamp;
    }

    /**
     * @notice Convert's Koro LP tokens back to Koro and Eth
     */
    function zapLPOut(uint256 _amount)
        private
        returns (uint256 _koroTokens, uint256 _ether)
    {
        (_koroTokens, _ether) = zapOut(_amount);
        (bool sent, ) = msg.sender.call{value: _ether}("");
        require(sent, "Failed to send Ether");
        koromaru.safeTransfer(msg.sender, _koroTokens);
    }

    function getEthBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getUserInfo(address _user)
        public
        view
        returns (
            uint256 amount,
            uint256 stakedInUsd,
            uint256 timeToHarves,
            uint256 pendingKoro,
            uint256 pendingEth
        )
    {
        amount = userInfo[_user].amount;
        timeToHarves = timeToHarvest(_user);
        (pendingKoro, pendingEth) = getPendingRewards(_user);

        uint256 stakedLP = koromaruUniV2.balanceOf(address(this));
        stakedInUsd = stakedLP > 0
            ? userInfo[_user].amount.mul(getStakedTVL()).div(stakedLP)
            : 0;
    }

    function getFarmInfo()
        public
        view
        returns (
            uint256 tvl,
            uint256 totalStaked,
            uint256 circSupply,
            uint256 dailyROI,
            uint256 ethDistribution,
            uint256 koroDistribution
        )
    {
        tvl = getStakedTVL();
        totalStaked = koromaruUniV2.balanceOf(address(this));
        circSupply = getCirculatingSupplyLocked();
        dailyROI = APR;
        ethDistribution = ethRewardAllocation;
        koroDistribution = koroRewardAllocation;
    }

    function getCirculatingSupplyLocked() public view returns (uint256) {
        address deadWallet = address(
            0x000000000000000000000000000000000000dEaD
        );
        IUniswapV2Pair koroPair = IUniswapV2Pair(address(koromaruUniV2));
        address token0 = koroPair.token0();
        (uint256 resv0, uint256 resv1, ) = koroPair.getReserves();
        uint256 koroResv = address(token0) == address(koromaru) ? resv0 : resv1;
        uint256 lpSupply = koromaruUniV2.totalSupply();
        uint256 koroCirculatingSupply = koromaru.totalSupply().sub(
            koromaru.balanceOf(deadWallet)
        );
        uint256 stakedLp = koromaruUniV2.balanceOf(address(this));

        return
            (stakedLp.mul(koroResv).mul(1e18).div(lpSupply)).div(
                koroCirculatingSupply
            ); // divide by 1e18
    }

    function approveRouterIfNotApproved() private {
        if (koromaru.allowance(address(this), address(uniswapRouter)) == 0) {
            koromaru.safeApprove(address(uniswapRouter), type(uint256).max);
        }

        if (
            koromaruUniV2.allowance(address(this), address(uniswapRouter)) == 0
        ) {
            koromaruUniV2.approve(address(uniswapRouter), type(uint256).max);
        }
    }

    function reachedMaxLimit() public view returns (bool) {
        uint256 lockedLP = koromaruUniV2.balanceOf(address(this));
        if (maxLPLimit < 1) return false; // unlimited

        if (lockedLP >= maxLPLimit) return true;

        return false;
    }

    //--------------- End Contract Utils  -------------------

    receive() external payable {
        emit IncreaseEthRewardPool(msg.value);
    }
}
