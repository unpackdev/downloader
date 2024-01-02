// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./AggregatorV3Interface.sol";
import "./TransferHelper.sol";
import "./Formula.sol";
import "./SavingsDaiMarket.sol";
import "./StEthMarket.sol";
import "./ICindexSwap.sol";

contract Vault is ERC20, Ownable, ReentrancyGuard, Pausable {

    struct AssetOracle {
        address asset;
        address oracle;
    }

    uint256 public protocolFee = 20;

    // Support staking coins (usdc,usdt,dai)
    address[] public supportAssets;

    mapping (address => AggregatorV3Interface) public oracles;

    mapping (address => uint256) assetAmounts;

    uint256 internal constant PRECISION = 10 ** 18;

    // sDai and stETH usd value weight
    uint256[] weights = [95, 5];

    address private immutable PROTOCOL_FEE_RESERVE;

    // cindex swap router
    ICindexSwap public router;

    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant STETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    // sDAI, stETH
    address[] public underlyingTokens = [0x83F20F44975D03b1b09e64809B757c47f942BEeA, 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84];

    event Deposit(address indexed user, uint256 share, address asset, uint256 amount, uint256 amount0, uint256 amount1, string referralCode);

    event DepositUnderlying(address indexed user, uint256 share, uint256 amount0, uint256 amount1);

    event Withdraw(address indexed user, uint256 share, address asset, uint256 amount, uint256 amount0, uint256 amount1);

    event WithdrawUnderlying(address indexed user, uint256 share, uint256 amount0, uint256 amount1);

    event ProtocolFee(uint256 amount0, uint256 amount1);

    struct DepositParams {
        address tokenIn;
        uint256 amountIn;
        ICindexSwap.SwapData[] swapData;
        string referralCode;
    }

    struct WithdrawParams {
        uint256 share;
        address tokenOut;
        ICindexSwap.SwapData[] swapData;
    }

    constructor(
    ) payable
        ERC20("US Treasury Bond + STETH", "TBE")
    {
        supportAssets = [address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48),address(0xdAC17F958D2ee523a2206206994597C13D831ec7),address(0x6B175474E89094C44Da98b954EedeAC495271d0F)];
        PROTOCOL_FEE_RESERVE = address(0x7c4FC00b404775E9Bf3996b1ad0c2b72799e994d);
        router = ICindexSwap(address(0x48740115ab1bd1E16dddE0D1c463C2568De0D492));
        oracles[address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)] = AggregatorV3Interface(address(0x986b5E1e1755e3C2440e960477f25201B0a8bbD4));
        oracles[address(0xdAC17F958D2ee523a2206206994597C13D831ec7)] = AggregatorV3Interface(address(0xEe9F2375b4bdF6387aa8265dD4FB8F16512A1d46));
        oracles[address(0x6B175474E89094C44Da98b954EedeAC495271d0F)] = AggregatorV3Interface(address(0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9));
        oracles[address(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84)] = AggregatorV3Interface(address(0xCfE54B5cD566aB89272946F602D76Ea879CAb4a8));
    }


    modifier onlyEOA {
        require(msg.sender == tx.origin, "EOA");
        _;
    }

    function isSupportAsset(address asset) public view returns (bool) {
        uint256 count = supportAssets.length;
        for(uint256 i = 0; i < count; i++) {
            if (supportAssets[i] == asset) {
                return true;
            }
        }
        return false;
    }

    /*
     *@dev deposit assets
     */
    function deposit(DepositParams memory params) external onlyEOA nonReentrant whenNotPaused returns (uint256){
        address tokenIn = params.tokenIn;
        uint256 amountIn = params.amountIn;
        string memory referralCode = params.referralCode;
        require(isSupportAsset(tokenIn), 'UnsupportedAsset');
        require(amountIn > 0, 'AmountInZero');
        ICindexSwap.SwapData[] memory swapData = params.swapData;
        require(swapData.length > 0, 'SwapDataZero');
        uint256 _sharePrePrice = sharePrePrice();
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
        calProtocolFee();
        uint256 amount0 = amountIn * weights[0] / 100;
        uint256 amount1 = amountIn * weights[1] / 100;
        (uint256[] memory prices, uint8[] memory decimals) = getPrices();
        uint256[] memory newAmounts = _deposit(tokenIn, amount0, amount1, swapData);
        uint256 share = Formula.dot(newAmounts, prices, decimals) * _sharePrePrice / PRECISION;
        _mint(msg.sender, share);
        updateAssetAmounts();
        emit Deposit(msg.sender, share, tokenIn, amountIn, newAmounts[0], newAmounts[1], referralCode);
        return share;
    }

    /*
    *@dev deposit sDai and mint token
    */
    function depositUnderlying(uint256 amount0) external onlyEOA nonReentrant whenNotPaused returns (uint256){
        require(amount0 > 0, 'Amount0InZero');
        uint256 _sharePrePrice = sharePrePrice();
        calProtocolFee();
        (uint256[] memory prices, uint8[] memory decimals) = getPrices();
        uint256 amount1 = amount0 * (prices[0] / (10 ** decimals[0])) * weights[1] / weights[0] / (prices[1] / (10 ** decimals[1]));
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amount0;
        amounts[1] = amount1;
        TransferHelper.safeTransferFrom(SavingsDaiMarket.sDAI, msg.sender, address(this), amounts[0]);
        TransferHelper.safeTransferFrom(StEthMarket.stETH, msg.sender, address(this), amounts[1]);
        uint256 share = Formula.dot(amounts, prices, decimals) * _sharePrePrice;
        _mint(msg.sender, share);
        updateAssetAmounts();
        emit DepositUnderlying(msg.sender, share, amounts[0], amounts[1]);
        return share;
    }

    /*
     *@dev withdraw shares
     */
    function withdraw(WithdrawParams memory params) external onlyEOA nonReentrant whenNotPaused {
        uint256 share = params.share;
        address tokenOut = params.tokenOut;
        require(isSupportAsset(tokenOut), 'UnsupportedAsset');
        require(share > 0, 'ShareZero');
        ICindexSwap.SwapData[] memory swapData = params.swapData;
        require(swapData.length > 0, 'SwapDataZero');
        uint256 totalSupply = totalSupply();
        calProtocolFee();
        //The number of coins to be withdrawn
        uint256[] memory amounts = getPoolAmounts();
        uint256 amount0 = amounts[0] * share / totalSupply;//sDAI
        uint256 amount1 = amounts[1] * share / totalSupply;//stETH
        _burn(msg.sender, share);
        //First change sDAI to DAI, then swap to the target currency
        ICindexSwap.SwapData memory stEthSwapData;
        if (tokenOut == DAI) {
            SavingsDaiMarket.redeem(amount0, msg.sender, address(this));
            stEthSwapData = swapData[0];
        } else {
            uint256 amount = SavingsDaiMarket.redeem(amount0, address(router), address(this));
            router.swap(DAI, amount, swapData[0]);
            stEthSwapData = swapData[1];
        }
        //Then swap stETH directly to the target currency
        TransferHelper.safeTransfer(STETH, address(router), amount1);
        router.swap(STETH, amount1, stEthSwapData);
        updateAssetAmounts();
        emit Withdraw(msg.sender, share, tokenOut, share, amount0, amount1);
    }

    /*
    *@dev withdraw share get underlying assets
    */
    function withdrawUnderlying(uint256 share) external onlyEOA nonReentrant whenNotPaused {
        require(share > 0, 'ShareZero');
        calProtocolFee();
        uint256 totalSupply = totalSupply();
        uint256[] memory amounts = getPoolAmounts();
        uint256 amount0Out = amounts[0] * share / totalSupply;
        uint256 amount1Out = amounts[1] * share / totalSupply;
        _burn(msg.sender, share);
        address token0Out = underlyingTokens[0];
        address token1Out = underlyingTokens[1];
        TransferHelper.safeTransfer(token0Out, msg.sender, amount0Out);
        TransferHelper.safeTransfer(token1Out, msg.sender, amount1Out);
        updateAssetAmounts();
        emit WithdrawUnderlying(msg.sender, share, amount0Out, amount1Out);
    }

    function updateAssetAmounts() internal {
        uint256 sDaiAmount = SavingsDaiMarket.balanceOf(address(this));
        uint256 exchangeRate = SavingsDaiMarket.exchangeRate();
        uint256 sETHAmount = StEthMarket.balanceOf(address(this));
        assetAmounts[SavingsDaiMarket.sDAI] = sDaiAmount * exchangeRate;
        assetAmounts[STETH] = sETHAmount;
    }

    /*
     *@dev Calculate fees
     */
    function calProtocolFee() internal {
        if (totalSupply() > 0) {
            //sDAI amount
            uint256 sDaiAmount = SavingsDaiMarket.balanceOf(address(this));
            uint256 exchangeRate = SavingsDaiMarket.exchangeRate();
            //stETH amount
            uint256 sETHAmount = StEthMarket.balanceOf(address(this));
            //Interest-earning assets during this period
            uint256 sDaiInterestAmount = (sDaiAmount * exchangeRate) - assetAmounts[SavingsDaiMarket.sDAI];
            uint256 sETHInterestAmount = sETHAmount - assetAmounts[StEthMarket.stETH];
            //Calculate protocol fees
            uint256 sDaiFeeAmount = sDaiInterestAmount * protocolFee / 100 / 1e18;
            uint256 sETHFeeAmount = sETHInterestAmount * protocolFee / 100;
            if (sDaiFeeAmount > 0) {
                TransferHelper.safeTransfer(SavingsDaiMarket.sDAI, PROTOCOL_FEE_RESERVE, sDaiFeeAmount);
            }
            if (sETHFeeAmount > 0) {
                TransferHelper.safeTransfer(STETH, PROTOCOL_FEE_RESERVE, sETHFeeAmount);
            }
            emit ProtocolFee(sDaiFeeAmount, sETHFeeAmount);
        }
    }
    
    function _deposit(address tokenIn, uint256 amount0, uint256 amount1, ICindexSwap.SwapData[] memory swapData) internal returns(uint256[] memory) {
        uint256[] memory amounts = new uint256[](2);
        uint256 sDaiAmount = _depositSavingDai(tokenIn, amount0, swapData);
        uint256 stEthAmount = _depositStEth(tokenIn, amount1, swapData);
        amounts[0] = sDaiAmount;
        amounts[1] = stEthAmount;
        return amounts;
    }

    /*
     *@dev Calculate the share corresponding to each price
     */
    function sharePrePrice() public view returns(uint256) {
        uint256[] memory poolAmounts = getPoolAmounts();
        (uint256[] memory prices, uint8[] memory decimals) = getPrices();
        uint256 value = Formula.dot(poolAmounts, prices, decimals);
        return totalSupply() > 0 ? totalSupply() * PRECISION / value : PRECISION;
    }

    /*
     *@dev query Pool Asset Amounts
     */
    function getPoolAmounts() public view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = IERC20(SavingsDaiMarket.sDAI).balanceOf(address(this));
        amounts[1] = IERC20(STETH).balanceOf(address(this));
        return amounts;
    }

    function _depositSavingDai(address token, uint256 amount, ICindexSwap.SwapData[] memory swapdata) internal returns (uint256) {
        if (amount == 0) {
            return 0;
        }
        if (token == DAI) {
            //The deposit is DAI, and the amount of coins in amount 0 does not require swap.
            return SavingsDaiMarket.deposit(amount, address(this));
        } else {
            uint256 beforeAmount = IERC20(DAI).balanceOf(address(this));
            // If it is not DAI, you need to perform two swaps. Change part of the tokenIn to DAI and store it in sDAI. Then change the other part of tokenIn to ETH and store it in stETH, which means you need to perform two swap operations.
            TransferHelper.safeTransfer(token, address(router), amount);
            ICindexSwap.SwapData memory _swapdata = swapdata[0];
            router.swap(token, amount, _swapdata);
            uint256 afterAmount = IERC20(DAI).balanceOf(address(this));

            return SavingsDaiMarket.deposit(afterAmount - beforeAmount, address(this));
        }
    }

    function _depositStEth(address token, uint256 amount, ICindexSwap.SwapData[] memory swapdata) internal returns (uint256) {
        if (amount == 0) {
            return 0;
        }
        uint256 beforeAmount = address(this).balance;
        TransferHelper.safeTransfer(token, address(router), amount);
        ICindexSwap.SwapData memory _swapdata;
        if (token == DAI) {
            _swapdata = swapdata[0];
        } else {
            _swapdata = swapdata[1];
        }
        router.swap(token, amount, _swapdata);
        uint256 afterAmount = address(this).balance;
        return StEthMarket.submit(address(0), afterAmount - beforeAmount);
    }

    function queryAssetValue(address asset, uint256 amount) internal view returns (uint256) {
        AggregatorV3Interface feed = oracles[asset];
        (,int256 price,,,) = feed.latestRoundData();
        uint8 decimals = feed.decimals();
        return uint256(price) * amount / (10 ** decimals);
    }

    function getPrices() public view returns (uint256[] memory, uint8[] memory) {
        uint256[] memory prices = new uint256[](2);
        uint8[] memory decimals = new uint8[](2);
        // query dai oracle price
        AggregatorV3Interface feed1 = oracles[DAI];
        (,int256 price,,,) = feed1.latestRoundData();
        // query dai converter sDai exchange rate
        uint256 exchangeRate = SavingsDaiMarket.exchangeRate();
        prices[0] = uint256(price) * exchangeRate / PRECISION;
        decimals[0] = feed1.decimals();
        
        AggregatorV3Interface feed2 = oracles[STETH];
        (,int256 price2,,,) = feed2.latestRoundData();
        prices[1] = uint256(price2);
        decimals[1] = feed2.decimals();

        return (prices, decimals);
    }

    function getProtocolFeeReserve() public view returns (address) {
        return PROTOCOL_FEE_RESERVE;
    }
    
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    receive() external payable {

    }

    fallback() external payable{

    }
}