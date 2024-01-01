// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";



interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}


interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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



    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}





contract OpenInfoToken is ERC20("Open Info Token", "OIT"), Ownable{
    using SafeMath for uint256;


    //======== Variables ========


    IUniswapV2Router02 public immutable uniswapV2Router;

    uint256 public constant MAX_SUPPLY  = 1*1e5*1e9;
    address public immutable uniswapV2Pair;
    address public constant deadAddress = address(0xdead);
    
    

    bool private isTradingEnabled = false;
    bool public swapEnabled = true;
    bool private swapping;

    address public utilityAddress;
    uint256 public enableTradingBlock;
    uint256 public maxHoldLimit = MAX_SUPPLY*2/100;

    uint256 public maxBuyLimitRate = 10; // 1% max buy during warmup time and 0% percent afterwards
    uint256 public maxSellLimitRate = 5; // 0.5% max sell amount forever
    uint256 public maxWarmupBlocks; // total numbers of blocks for warmup period
    uint256 public swapTokensAtAmount;

    uint256 public normalBuyFee =50; //5%
    uint256 public normalSellFee =50; //5%

    mapping(address => bool) private isExcludedFromFees;
    mapping(address => bool) public isExcludedMaxTransactionLimit;
    mapping(address => bool) public isExcludedMaxHoldLimit;

    mapping(address => bool) public automatedMarketMakerPairs;

    //======== Events ========

    event onTradingEnabled();
    event onExcludeFromFees(address indexed account, bool isExcluded);
    event onExcludeFromMaxHoldLimit(address indexed account, bool isExcluded);
    event onExcludeFromMaxTransactionLimit(address indexed account, bool isExcluded);

    event onSetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event onUtilityWalletUpdated( address indexed newWallet,address indexed oldWallet);
    event onSwapAndLiquify(
        uint256 initialBalance,
        uint256 liquidityShareInETH,
        uint256 utilityShareInETH
    );
    event onFeeChanged(uint256 preBuyFee,uint256 newBuyFee,uint256 preSellFee,uint256 newSellFee);

    constructor(address _utilityAddress, address _routerAddress)  {
        utilityAddress = _utilityAddress;
       
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_routerAddress);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        excludeFromFees(owner(),true);
        excludeFromFees(address(this), true);
        excludeFromFees(deadAddress, true);
        excludeFromFees(_utilityAddress,true);

        excludeFromMaxTransactionLimit(address(uniswapV2Pair), true);
        excludeFromMaxTransactionLimit(owner(), true);
        excludeFromMaxTransactionLimit(address(this), true);
        excludeFromMaxTransactionLimit(deadAddress, true);
        excludeFromMaxTransactionLimit(_utilityAddress, true);

        excludeFromMaxHoldLimit(address(uniswapV2Pair), true);
        excludeFromMaxHoldLimit(owner(), true);
        excludeFromMaxHoldLimit(address(this), true);
        excludeFromMaxHoldLimit(deadAddress, true);
        excludeFromMaxHoldLimit(_utilityAddress, true);

        uint256 kolShare = MAX_SUPPLY*2/100; // KOLs
        _mint(address(0x09F47eca127cf7f8D36597216bb11D8765e22be7),kolShare);
        _mint(address(0xaB59555Ef7e65aDd9862718115c9AF839c7DDb0f),kolShare);
        _mint(address(0x9Cc0829EBBd8028229CD9ab54D1dc025Ea582199),kolShare);

        uint256 utilityShare = MAX_SUPPLY*14/100; // 8% rewards, 6% team. locked
        _mint(_utilityAddress,utilityShare);

        _mint(msg.sender,MAX_SUPPLY-utilityShare-kolShare-kolShare-kolShare);
        swapTokensAtAmount = (totalSupply()*5)/1000;
    }


    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    receive() external payable {}
     
    // this function is used to register/unregister lp addresses in order to find out if transfer is buy or sell
   function setAutomatedMarketMakerPair(address pair, bool isAdd) public onlyOwner{
        automatedMarketMakerPairs[pair] = isAdd;
        emit onSetAutomatedMarketMakerPair(pair, isAdd);
    }

    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    // this function is used to register/unregister lp addresses in order to find out if transfer is buy or sell
   function excludeFromMaxTransactionLimit(address account, bool excluded) public onlyOwner {
        isExcludedMaxTransactionLimit[account] = excluded;
        emit onExcludeFromMaxTransactionLimit(account, excluded);
    }
    
    // this function is used to exclude/include wallet addresses from max hold limit 
    function excludeFromMaxHoldLimit(address account, bool excluded) public onlyOwner {
        isExcludedMaxHoldLimit[account] = excluded;
        emit onExcludeFromMaxHoldLimit(account, excluded);
    }

    // this function is used to update utilityWallet where token fee will go
    function updateUtilityWallet(address newutilityAddress) external onlyOwner {
        emit onUtilityWalletUpdated(utilityAddress, newutilityAddress);
        utilityAddress = newutilityAddress;
    }

    // this function is used to remove maxhold limit and max buy limit
    function removeLimits() public onlyOwner{
        maxHoldLimit =totalSupply();
        maxBuyLimitRate = 1000; //100%
    }

    
    // this function is used to change maxhold limit and max buy limit
    function changeLimits(uint256 maxBuyLimitInPercent,uint256 maxHoldLimitInPercent) public onlyOwner{
        maxBuyLimitRate = maxBuyLimitInPercent;
        maxHoldLimitInPercent = maxHoldLimitInPercent;
    }

    // this function is change buy and sell fee , buy and sell fee can't be set more than 5%
    function changeBuyAndSellFee(uint256 buyFee,uint256 sellFee) public onlyOwner{
        require(buyFee  <= 50,"cant set buy fee more than 5%");
        require(sellFee  <= 50,"cant set sell fee more than 5%");
        emit onFeeChanged(normalBuyFee,buyFee,normalSellFee,sellFee);

        normalBuyFee = buyFee;
        normalSellFee = sellFee;
    }

    // this function is used to exclude address from txn fee
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        isExcludedFromFees[account] = excluded;
        emit onExcludeFromFees(account, excluded);
    }


    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    // this function will return true if warmup time is active or not where fee will be higher during warmup time
    function isWarmupTime() public view returns(bool){
        if(isTradingEnabled == true){
            return enableTradingBlock+maxWarmupBlocks > block.number;
        }
        return true;
    }


    // this function is used to update max swap token threshold
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 5) / 1000,
            "Swap amount cannot be higher than 0.5% total supply."
        );
        swapTokensAtAmount = newAmount;
    }

    // returns current buy and sell fee percents
    function getTxnFee() private  view returns(uint256 buyFee,uint256 sellFee){
        if(isWarmupTime()){
            uint256 passedBlocks =  block.number - enableTradingBlock;
            if(passedBlocks ==0 || passedBlocks==1 || passedBlocks==2){
                buyFee = 990; //99%
                sellFee = 990; //99%
            }else if(passedBlocks >2 && passedBlocks <6){
                buyFee = 500; //50%
                sellFee = 500; //50%
            }else if(passedBlocks >5 && passedBlocks <9){
                buyFee = 300; //30%
                sellFee = 300; //30%
            }else {
                buyFee = 100; //10%
                sellFee = 100; //10%
            }
        }else{
            buyFee = normalBuyFee;
            sellFee = normalSellFee;
        }
    } 


    // used to enable trade takes number of warmup blocks
    function onsGaanNouBraai(uint256 _maxWarmupBlocks) public onlyOwner {
        isTradingEnabled = true;
        enableTradingBlock = block.number;
        maxWarmupBlocks  = _maxWarmupBlocks;
        emit onTradingEnabled();
    }


    // used to convert tokens to eth internally 
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }



    // used to convert tokens to eth internally 
    function swapAndLiquify(uint256 balance) private lockTheSwap {

        uint256 initialBalance = address(this).balance;
        uint256 convertingToETH = balance*90/100;
        uint256 liquidityShareInTokens = balance*10/100;
        swapTokensForEth(convertingToETH); 
        uint256 newBalance = address(this).balance.sub(initialBalance);
        uint256 utilityShareInETH  = newBalance*80/100;
        uint256 liquidityShareInETH  = newBalance*20/100;
        payable(utilityAddress).transfer(utilityShareInETH);
        addLiquidity(liquidityShareInTokens, liquidityShareInETH);
        emit onSwapAndLiquify(initialBalance, liquidityShareInETH, utilityShareInETH);
    }



    // used to add tokens liquidty
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, 
            0, 
            deadAddress,
            block.timestamp
        );
    }



    function _transfer(address from, address to, uint256 amount) internal  override virtual {
       
        if(owner() == from || owner() == to){
            super._transfer(from,to,amount);
            return;
        }

        require(isTradingEnabled,"Trading not enabled");
    
        bool isBuy = automatedMarketMakerPairs[from];
        bool isSell = automatedMarketMakerPairs[to];

        if(!isExcludedMaxTransactionLimit[from]){
            if(isBuy){
                require(amount <= maxBuyLimitRate*totalSupply()/1000,"Limit Reached");
            }else if(isSell){
                require(amount <= maxSellLimitRate*totalSupply()/1000,"Limit Reached");
            }
        }

        if(!isExcludedMaxHoldLimit[to]){
            require(amount+balanceOf(to)<= maxHoldLimit,"Max Hold Limit Reached");
        }


        bool isTakeFee = !isExcludedFromFees[from] && (isBuy || isSell);

        if(isTakeFee){
            (uint256 buyFee,uint256 sellFee) = getTxnFee();
            if(isBuy){
                uint256 buyFeeAmount = amount * buyFee /1000;
                if(buyFeeAmount >0){
                    super._transfer(from,address(this),buyFeeAmount);
                }
                super._transfer(from,to,amount-buyFeeAmount);
            }else if(isSell){
                uint256 sellFeeAmount = amount * sellFee /1000;
                if(sellFeeAmount >0){
                    super._transfer(from,address(this),sellFeeAmount);
                }
                super._transfer(from,to,amount-sellFeeAmount);
            }
        }else{
            super._transfer(from,to,amount);
        }

        
        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

         if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from]) {
            swapAndLiquify(contractTokenBalance);
        }

    }


}
