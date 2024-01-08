// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./IHegicETHOptions.sol";
import "./ICurve.sol";
import "./IUniswapV2Router02.sol";
import "./IChainlinkAggregatorV3.sol";
import "./IERC20.sol";
import "./IWETH.sol";
import "./ITBDv2.sol";
import "./TBDFees.sol";

import "./SafeMath.sol";
import "./Ownable.sol";

contract TBDETHv2 is TBDFees, ITBDv2 {
    using SafeMath for uint256;

    // Curve MetaPool used to convert alUSD to Dai
    ICurve alUSDMetaPool;

    // Hegic ETH Options contract
    IHegicETHOptions hegicETHOptions;

    // Uniswap router to convert Dai to Eth
    IUniswapV2Router02 uniswapV2Router02;

    // alUSD, Dai and Weth ERC20 contracts
    IERC20 alUSD;
    IERC20 Dai;
    IWETH Weth;

    // Store of created options
    mapping(address => ITBDv2.Option[]) public optionsByOwner;

    // Uniswap exchange paths Dai => Eth
    address[] public uniswapExchangePath;

    // Decimals for price values from aggregators
    uint256 constant PRICE_DECIMALS = 1e8;

    constructor(
        address _hegicETHOptions,
        address _alUSD,
        address _Dai,
        address _Weth,
        address _alUSDMetaPool,
        address _uniswapV2Router02,
        address _owner,
        uint256 _fee
    ) {
        require(_fee <= FEE_DECIMALS, 'TBDv2/invalid-fee-amount');
        require(_alUSDMetaPool != address(0), 'TBDv2/null-alusd-pool');
        require(_hegicETHOptions != address(0), 'TBDv2/null-hegic-eth-options');
        require(_alUSD != address(0), 'TBDv2/null-alusd');
        require(_Dai != address(0), 'TBDv2/null-dai');
        require(_Weth != address(0), 'TBDv2/null-weth');
        require(_uniswapV2Router02 != address(0), 'TBDv2/null-uniswap-router');

        alUSDMetaPool = ICurve(_alUSDMetaPool);
        hegicETHOptions = IHegicETHOptions(_hegicETHOptions);
        alUSD = IERC20(_alUSD);
        Dai = IERC20(_Dai);
        Weth = IWETH(_Weth);
        uniswapV2Router02 = IUniswapV2Router02(_uniswapV2Router02);
        fee = _fee;
        uniswapExchangePath = new address[](2);
        uniswapExchangePath[0] = _Dai;
        uniswapExchangePath[1] = _Weth;

        Ownable.transferOwnership(_owner);

        emit ChangeFee(owner(), fee);

    }

    /// ITBDv2 overriden functions

    function purchaseOptionWithAlUSD(
        uint256 amount,
        uint256 strike,
        uint256 period,
        address owner,
        IHegicOptionTypes.OptionType optionType,
        uint256 minETH
    ) public override returns (uint256 optionID) {
        // Retrieve alUSD from user
        require(alUSD.transferFrom(msg.sender, address(this), amount), 'TBDv2/cannot-transfer-alusd');

        // Compute curve output amount in Dai
        uint256 curveDyInDai = alUSDMetaPool.get_dy_underlying(0, 1, amount);
        // Approve alUSD for curve
        alUSD.approve(address(alUSDMetaPool), amount);
        // Swap alUSD to Dai
        require(
            alUSDMetaPool.exchange_underlying(int128(0), int128(1), amount, curveDyInDai) == curveDyInDai,
            'TBDv2/cannot-swap-alusd-to-dai'
        );

        // Compute amount of Eth retrievable from Swap & check if above minimal Eth value provided
        // Doing it soon prevents extra gas usage in case of failure due to useless approvale and swap
        uint256[] memory uniswapAmounts = uniswapV2Router02.getAmountsOut(curveDyInDai, uniswapExchangePath);
        require(computeAmountWithFees(uniswapAmounts[1]) > minETH, 'TBDv2/min-eth-not-reached');

        // Approve Dai to Uniswap Router
        Dai.approve(address(uniswapV2Router02), curveDyInDai);

        // Swap Dai for Eth
        uniswapAmounts =
            uniswapV2Router02.swapExactTokensForETH(
                curveDyInDai,
                minETH,
                uniswapExchangePath,
                address(this),
                block.timestamp
            );

        uint256 optionAmountWithFees = computeAmountWithFees(uniswapAmounts[1]);

        // Reverse compute option amount
        uint256 optionAmount = getAmount(period, optionAmountWithFees, strike, optionType);

        // Create and send option to owner
        optionID = hegicETHOptions.create{value: optionAmountWithFees}(period, optionAmount, strike, optionType);
        hegicETHOptions.transfer(optionID, payable(owner));

        emit PurchaseOption(owner, optionID, amount, address(alUSD), optionAmountWithFees, uniswapAmounts[1] - optionAmountWithFees);

        // Store option
        optionsByOwner[msg.sender].push(ITBDv2.Option({id: optionID, priceInAlUSD: amount}));

        return optionID;
    }

    function getOptionsByOwner(address owner) external view override returns (ITBDv2.Option[] memory) {
        return optionsByOwner[owner];
    }

    function getUnderlyingFeeFromAlUSD(uint256 amount) external view override returns (uint256) {
        uint256 curveDyInDai = alUSDMetaPool.get_dy_underlying(0, 1, amount);
        return computeAmountWithFees(uniswapV2Router02.getAmountsOut(curveDyInDai, uniswapExchangePath)[1]);
    }

    function getEthFeeFromAlUSD(uint256 amount) external view override returns (uint256) {
        uint256 curveDyInDai = alUSDMetaPool.get_dy_underlying(0, 1, amount);
        return computeAmountWithFees(uniswapV2Router02.getAmountsOut(curveDyInDai, uniswapExchangePath)[1]);
    }

    function getOptionAmountFromAlUSD(
        uint256 period,
        uint256 amount,
        uint256 strike,
        IHegicOptionTypes.OptionType optionType
    ) external view override returns (uint256) {
        uint256 curveDyInDai = alUSDMetaPool.get_dy_underlying(0, 1, amount);
        uint256[] memory uniswapWethOutput = uniswapV2Router02.getAmountsOut(curveDyInDai, uniswapExchangePath);

        return getAmount(period, computeAmountWithFees(uniswapWethOutput[1]), strike, optionType);
    }

    function getAmount(
        uint256 period,
        uint256 fees,
        uint256 strike,
        IHegicOptionTypes.OptionType optionType
    ) public view override returns (uint256) {
        require(
            optionType == IHegicOptionTypes.OptionType.Put || optionType == IHegicOptionTypes.OptionType.Call,
            'TBDv2/invalid-option-type'
        );
        (, int256 latestPrice, , , ) = IChainlinkAggregatorV3(hegicETHOptions.priceProvider()).latestRoundData();
        uint256 currentPrice = uint256(latestPrice);
        uint256 iv = hegicETHOptions.impliedVolRate();

        if (optionType == IHegicOptionTypes.OptionType.Put) {
            if (strike > currentPrice) {
                // ITM Put Fee
                uint256 nume = fees.mul(currentPrice).mul(PRICE_DECIMALS);
                uint256 sqrtPeriod = sqrt(period);
                uint256 denom = currentPrice.mul(PRICE_DECIMALS).div(100);
                denom = denom.add(sqrtPeriod.mul(iv).mul(strike));
                denom = denom.add(PRICE_DECIMALS.mul(strike.sub(currentPrice)));
                return nume.div(denom);
            } else {
                // OTM Put Fee
                uint256 nume = fees.mul(currentPrice).mul(PRICE_DECIMALS);
                uint256 sqrtPeriod = sqrt(period);
                uint256 denom = sqrtPeriod.mul(strike).mul(iv).add(currentPrice.mul(PRICE_DECIMALS).div(100));
                return nume.div(denom);
            }
        } else {
            if (strike < currentPrice) {
                // ITM Call Fee
                uint256 nume = fees.mul(strike).mul(PRICE_DECIMALS).mul(currentPrice);
                uint256 sqrtPeriod = sqrt(period);
                uint256 denom = strike.mul(PRICE_DECIMALS).div(100).mul(currentPrice);
                denom = denom.add(sqrtPeriod.mul(iv).mul(currentPrice).mul(currentPrice));
                denom = denom.add(strike.mul(PRICE_DECIMALS).mul(currentPrice.sub(strike)));
                return nume.div(denom);
            } else {
                // OTM Call Fee
                uint256 nume = fees.mul(strike).mul(PRICE_DECIMALS);
                uint256 sqrtPeriod = sqrt(period);
                uint256 denom = sqrtPeriod.mul(currentPrice).mul(iv).add(strike.mul(PRICE_DECIMALS).div(100));
                return nume.div(denom);
            }
        }
    }

    /// Misc

    function sqrt(uint256 x) private pure returns (uint256 result) {
        result = x;
        uint256 k = x.div(2).add(1);
        while (k < result) (result, k) = (k, x.div(k).add(k).div(2));
    }

    receive() external payable {}

}
