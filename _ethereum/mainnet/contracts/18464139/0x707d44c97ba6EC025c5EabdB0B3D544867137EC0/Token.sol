// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;
//
//          _______                   _____                _____          
//         /::\    \                 /\    \              /\    \         
//        /::::\    \               /::\    \            /::\    \        
//       /::::::\    \              \:::\    \           \:::\    \       
//      /::::::::\    \              \:::\    \           \:::\    \      
//     /:::/~~\:::\    \              \:::\    \           \:::\    \     
//    /:::/    \:::\    \              \:::\    \           \:::\    \    
//   /:::/    / \:::\    \             /::::\    \          /::::\    \   
//  /:::/____/   \:::\____\   ____    /::::::\    \        /::::::\    \  
// |:::|    |     |:::|    | /\   \  /:::/\:::\    \      /:::/\:::\    \ 
// |:::|____|     |:::|    |/::\   \/:::/  \:::\____\    /:::/  \:::\____\
//  \:::\    \   /:::/    / \:::\  /:::/    \::/    /   /:::/    \::/    /
//   \:::\    \ /:::/    /   \:::\/:::/    / \/____/   /:::/    / \/____/ 
//    \:::\    /:::/    /     \::::::/    /           /:::/    /          
//     \:::\__/:::/    /       \::::/____/           /:::/    /           
//      \::::::::/    /         \:::\    \           \::/    /            
//       \::::::/    /           \:::\    \           \/____/             
//        \::::/    /             \:::\    \                              
//         \::/____/               \:::\____\                             
//          ~~                      \::/    /                             
//                                   \/____/                              
//
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

/**
 * @title OpenInfoToken
 * @author Prozeb & Werner
 * @notice This contract is used for the Open Info Token (OIT) ERC20 token.
 * The contract inherits from the ERC20 and Ownable contracts.
 * The token has a maximum supply of 1 million tokens.
 * The contract uses the Uniswap V2 Router for swapping tokens and adding liquidity.
 */
contract OpenInfoToken is ERC20("Open Info Token", "OIT"), Ownable{
    using SafeMath for uint256;


    //======== Variables ========
    IUniswapV2Router02 public immutable uniswapV2Router;

    uint256 public constant MAX_SUPPLY  = 1*1e6*1e9; // 1m
    address public immutable uniswapV2Pair;
    address public constant deadAddress = address(0xdead);

    bool private isTradingEnabled = false;
    bool public swapEnabled = true;
    bool private swapping;

    address public utilityAddress;
    uint256 public enableTradingBlock;
    uint256 public maxHoldLimit = MAX_SUPPLY*2/100;

    uint256 public maxBuyLimitRate = 10; // 1% max buy
    uint256 public maxSellLimitRate = 5; // 0.5% max sell amount forever
    uint256 public maxWarmupBlocks = 15; // total numbers of blocks for warmup period
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


    constructor(address _utilityAddress, address _routerAddress, address _kolSeedAddress)  {
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
        excludeFromMaxHoldLimit(_kolSeedAddress, true); // KOLs funds distributed from this address

        uint256 kolShare = MAX_SUPPLY*6/100; // 6% for KOLs
        _mint(_kolSeedAddress,kolShare);

        uint256 utilityShare = MAX_SUPPLY*14/100; // 8% rewards, 6% team. both locked
        _mint(_utilityAddress,utilityShare);

        _mint(msg.sender,MAX_SUPPLY-utilityShare-kolShare); // 80% for liquidity + airdrop
        swapTokensAtAmount = (totalSupply()*1)/1000; // 0.1% of total supply
    }


    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }


    receive() external payable {}


    /**
     * @dev This function is used to register/unregister lp addresses in order to find out if transfer is buy or sell.
     * @param pair The address of the LP pair to register/unregister.
     * @param isAdd A boolean indicating whether to register or unregister the LP pair.
     */
    function setAutomatedMarketMakerPair(address pair, bool isAdd) public onlyOwner{
        automatedMarketMakerPairs[pair] = isAdd;
        emit onSetAutomatedMarketMakerPair(pair, isAdd);
    }


    /**
     * @dev This function is used to disable contract sales if absolutely necessary (emergency use only).
     * @param enabled A boolean indicating whether to enable or disable swapping of the token.
     */
    function updateSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }


    /**
     * @dev This function is used to exclude/include wallet addresses from max transaction limit.
     * @param account The address of the wallet to exclude/include.
     * @param excluded A boolean indicating whether to exclude or include the wallet.
     */
    function excludeFromMaxTransactionLimit(address account, bool excluded) public onlyOwner {
        isExcludedMaxTransactionLimit[account] = excluded;
        emit onExcludeFromMaxTransactionLimit(account, excluded);
    }


    /**
     * @dev This function is used to exclude/include wallet addresses from max hold limit.
     * @param account The address of the wallet to exclude/include.
     * @param excluded A boolean indicating whether to exclude or include the wallet.
     */
    function excludeFromMaxHoldLimit(address account, bool excluded) public onlyOwner {
        isExcludedMaxHoldLimit[account] = excluded;
        emit onExcludeFromMaxHoldLimit(account, excluded);
    }


    /**
     * @dev This function is used to update the utility wallet address.
     * @param newUtilityAddress The new utility wallet address.
     */
    function updateUtilityWallet(address newUtilityAddress) external onlyOwner {
        emit onUtilityWalletUpdated(utilityAddress, newUtilityAddress);
        utilityAddress = newUtilityAddress;
    }


    /**
     * @dev This function is used to remove the buy transaction and hold limits.
     */
    function removeLimits() external onlyOwner{
        maxHoldLimit =totalSupply();
        maxBuyLimitRate = 1000; //100%
    }


    /**
     * @dev This function is used to change the buy transaction and hold limits.
     * @param maxBuyLimitInPercent The new maximum transaction limit, expressed in tenths of a percent.
     * @param maxHoldLimitInPercent The new maximum hold limit, expressed in tenths of a percent.
     */
    function changeLimits(uint256 maxBuyLimitInPercent,uint256 maxHoldLimitInPercent) external onlyOwner{
        if(!(maxBuyLimitInPercent  >= 10)){
            revert("cant set buy limit less than 1%");
        }
        if(!(maxHoldLimitInPercent  >= 20)){
            revert("cant set hold limit less than 2%");
        }
        
        maxBuyLimitRate = maxBuyLimitInPercent;
        maxHoldLimitInPercent = maxHoldLimitInPercent;
    }


    /**
     * @dev This function is used to change the buy and sell fees.
     * @param buyFee The new buy fee, expressed in tenths of a percent.
     * @param sellFee The new sell fee, expressed in tenths of a percent.
     */
    function changeBuyAndSellFee(uint256 buyFee,uint256 sellFee) external onlyOwner{
        if(!(buyFee  <= 50)){
            revert("cant set buy fee more than 5%");
        }

        if(!(sellFee  <= 50)){
            revert("cant set sell fee more than 5%");
        }

        emit onFeeChanged(normalBuyFee,buyFee,normalSellFee,sellFee);

        normalBuyFee = buyFee;
        normalSellFee = sellFee;
    }


    /**
     * @dev This function is used to exclude/include wallet addresses from fees.
     * @param account The address of the wallet to exclude/include.
     * @param excluded A boolean indicating whether to exclude or include the wallet.
     */
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        isExcludedFromFees[account] = excluded;
        emit onExcludeFromFees(account, excluded);
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * @return The number of decimals in the token's smallest unit.
     */
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }


    /**
     * @dev Returns whether the warmup time is active or not.
     * @return A boolean indicating whether the warmup time is active or not.
     */
    function isWarmupTime() public view returns(bool){
        if(isTradingEnabled == true){
            return enableTradingBlock+maxWarmupBlocks > block.number;
        }
        return true;
    }


    /**
     * @dev Updates the maximum swap token threshold.
     * @param newAmount The new maximum swap token threshold.
     */
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
        if(!(newAmount >= (totalSupply() * 1) / 100000)){
            revert("Swap amount cannot be lower than 0.001% total supply.");
        }

        if(!( newAmount <= (totalSupply() * 5) / 1000)){
            revert("Swap amount cannot be higher than 0.5% total supply.");
        }
        swapTokensAtAmount = newAmount;
    }


    /**
     * @dev Returns the transaction fee for a given amount of tokens.
     * @return buyFee the current buy fee, expressed as tenths of a percent.
     * @return sellFee the current sell fee, expressed as tenths of a percent.
     */
    function getTxnFee() private  view returns(uint256 buyFee,uint256 sellFee){
        if(isWarmupTime()){
            uint256 passedBlocks =  block.number - enableTradingBlock;
            if(passedBlocks < 7){
                buyFee = 500; //50%
                sellFee = 500; //50%
            }else {
                buyFee = 250; //25%
                sellFee = 250; //25%
            }
        }else{
            buyFee = normalBuyFee;
            sellFee = normalSellFee;
        }
    } 


    /**
     * @dev Used to enable trading after the pre-specified specified number of warmup blocks.
     */
    function goBokke() external onlyOwner {
        isTradingEnabled = true;
        enableTradingBlock = block.number;
        emit onTradingEnabled();
    }


    /**
     * @dev Swaps given tokens for ETH.
     * @param tokenAmount The amount of tokens to swap.
     */
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


    /**
     * @dev Swaps nine tenths of the given tokens for ETH and adds a tenth of the tokens to the liquidity in the Uniswap pool.
     * @param balance The balance of tokens to be swapped and liquified.
     */
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


    /**
     * @dev Used to add tokens liquidity to the Uniswap pool.
     * @param tokenAmount The amount of tokens to be added as liquidity.
     * @param ethAmount The amount of ETH to be added as liquidity.
     */
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


    /**
     * @dev Internal transfer function. Overridden to meet tokenomics of the token, see https://vrfd.info/token.
     * @param from Address of the sender.
     * @param to Address of the recipient.
     * @param amount Amount to be transferred.
     */
    function _transfer(address from, address to, uint256 amount) internal  override virtual {
        if(owner() == from || owner() == to){
            super._transfer(from,to,amount);
            return;
        }

        if(!isTradingEnabled){
            revert("Trading not enabled");
        }
        bool isBuy = automatedMarketMakerPairs[from];
        bool isSell = automatedMarketMakerPairs[to];

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from]) {
            swapAndLiquify(swapTokensAtAmount);
        }
        if(!isExcludedMaxTransactionLimit[from]){
            if(isBuy){
                if(!(amount <= maxBuyLimitRate*totalSupply()/1000)){
                    revert("Limit Reached");
                }
            }else if(isSell){
                if(!(amount <= maxSellLimitRate*totalSupply()/1000)){
                    revert("Limit Reached");
                }
            }
        }

        if(!isExcludedMaxHoldLimit[to]){
            if(!(amount+balanceOf(to)<= maxHoldLimit)){
                revert("Max Hold Limit Reached");
            }
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
    }

    /**
     * @dev Used to transfer the contract's ETH balance to the contract owner.
     */
    function takeETH() external onlyOwner{
        (bool success,) = msg.sender.call{value:address(this).balance}("");
        if(!success) revert("Can't Withdraw");
    }
}
