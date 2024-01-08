// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "./OwnableUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./Initializable.sol";
import "./ERC20Upgradeable.sol";

import "./SafeMath.sol";

import "./IUniswap.sol";
import "./ExoticRewardsTracker.sol"; 

contract Exotic is     
    Initializable,
    ContextUpgradeable,
    OwnableUpgradeable,
    ERC20Upgradeable 
{
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    uint256 public ETHRewardsFee;

    uint256 public liquidityFee;
    uint256 public teamFee;
    
    uint256 public notHoldersFee;
    uint256 public totalFees;

    bool private swapping;

    ExoticRewardsTracker public rewardsTracker;

    address public liquidityWallet;
    address payable public teamWallet;

    uint256 public swapTokensAtAmount;
    uint256 public maxSellTransactionAmount;

    // Include this from the client request
    uint256 public excludeFromFeesUntilAtAmount;
    bool public useExcludeFromFeesUntilAtAmount;

    uint256 public sellFeeIncreaseFactor;

    uint256 public gasForProcessing;

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;

    // store addresses that an automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateRewardsTracker(address indexed newAddress, address indexed oldAddress);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event SwapForNotHolders(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SendRewardsForHolders(
    	uint256 tokensSwapped,
    	uint256 amount
    );

    event ProcessedRewardsTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );

    event ChangeFees(
        uint256 newEthRewardsFee,
        uint256 newLiquidityFee,
        uint256 newTeamFee
    );

    function initialize() initializer public {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ERC20_init("Exotic Metaverse", "EXOTIC");

        ETHRewardsFee = 2;

        liquidityFee = 2;
        teamFee = 6;
        notHoldersFee = liquidityFee.add(teamFee);
        
        totalFees = 10;

        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
        .createPair(address(this), uniswapV2Router.WETH());

    	rewardsTracker = ExoticRewardsTracker(payable(0xB36e347Bbbd6cbEf31BF7d0AE50Abb11Cc78ECc5));

    	liquidityWallet = owner();

        teamWallet = payable(0x6e8c9AF9715A9bb9D28F2e139C811F6eB47d47F0);

        swapTokensAtAmount = 5000 * (10**18); 
        maxSellTransactionAmount = 200000 * (10**18);

        excludeFromFeesUntilAtAmount = 1000 * (10**18);
        useExcludeFromFeesUntilAtAmount = true;

        // sells have fees of 12 and 6 (10 * 1.2 and 5 * 1.2)
        sellFeeIncreaseFactor = 120;

        // use by default 300,000 gas to process auto-claiming rewards
        gasForProcessing = 300000;

        automatedMarketMakerPairs[uniswapV2Pair] = true;

        excludeFromFees(liquidityWallet, true);
        excludeFromFees(address(this), true);
        
        _mint(owner(), 10000000 * (10**18));
    }

    receive() external payable {

  	}

    function updateRewardsTracker(address newAddress) public onlyOwner {
        ExoticRewardsTracker newRewardsTracker = ExoticRewardsTracker(payable(newAddress));

        require(newRewardsTracker.owner() == address(this), "The new one must be owned by the EXOTIC token contract");

        newRewardsTracker.excludeFromRewards(address(newRewardsTracker));
        newRewardsTracker.excludeFromRewards(address(this));
        newRewardsTracker.excludeFromRewards(owner());
        newRewardsTracker.excludeFromRewards(address(uniswapV2Router));

        emit UpdateRewardsTracker(newAddress, address(rewardsTracker));

        rewardsTracker = newRewardsTracker;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function changeFees(uint256 newEthRewardsFee, uint256 newLiquidityFee, uint256 newTeamFee) external onlyOwner {
        ETHRewardsFee = newEthRewardsFee;
        liquidityFee = newLiquidityFee;
        teamFee = newTeamFee;

        notHoldersFee = liquidityFee.add(teamFee);
        totalFees = ETHRewardsFee.add(liquidityFee).add(teamFee);

        emit ChangeFees(ETHRewardsFee, liquidityFee, teamFee);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }
    
    function excludeFromRewards(address account) external onlyOwner {
        rewardsTracker.excludeFromRewards(account);
    }
    
    function setSellFactor(uint256 newFactor) external onlyOwner {
        sellFeeIncreaseFactor = newFactor;
    }
    
    function setSwapAtAmount(uint256 newAmount) external onlyOwner {
        swapTokensAtAmount = newAmount * (10**18);
    }

    function setExcludeFromFeesUntilAtAmount(uint256 newAmount) external onlyOwner {
        excludeFromFeesUntilAtAmount = newAmount * (10**18);
    }

    function setUseExcludeFromFeesUntilAtAmount(bool use) external onlyOwner {
        useExcludeFromFeesUntilAtAmount = use;
    }
    
    function changeMinimumHoldingLimit(uint256 newLimit) public onlyOwner {
        rewardsTracker.setMinimumTokenBalanceForRewards(newLimit);
    }
        
    function changeMaxSellAmount(uint256 newAmount) external onlyOwner {
        maxSellTransactionAmount = newAmount * (10**18);
    }
        
    function changeTeamWallet(address payable newAddress) external onlyOwner {
        teamWallet = newAddress;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The Uniswap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            rewardsTracker.excludeFromRewards(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }
    
    function updateLiquidityWallet(address newLiquidityWallet) public onlyOwner {
        excludeFromFees(newLiquidityWallet, true);
        emit LiquidityWalletUpdated(newLiquidityWallet, liquidityWallet);
        liquidityWallet = newLiquidityWallet;
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "Must be between the 200000 and 500000");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        rewardsTracker.updateClaimWait(claimWait);
    }

    function getClaimWait() external view returns(uint256) {
        return rewardsTracker.claimWait();
    }
    
    function minimumLimitForRewards() public view returns(uint256) {
        return rewardsTracker.minimumTokenLimit();
    }

    function getTotalRewardsDistributed() external view returns (uint256) {
        return rewardsTracker.totalRewardsDistributed();
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }
    
    function isExcludedFromRewards(address account) public view returns(bool) {
        return rewardsTracker.excludedFromRewards(account);
    }

    function withdrawableRewardsOf(address account) public view returns(uint256) {
    	return rewardsTracker.withdrawableRewardOf(account);
  	}

	function rewardsTokenBalanceOf(address account) public view returns (uint256) {
		return rewardsTracker.balanceOf(account);
	}

    function getAccountRewardsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return rewardsTracker.getAccount(account);
    }

	function getAccountRewardsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	return rewardsTracker.getAccountAtIndex(index);
    }

	function processRewardsTracker(uint256 gas) external {
		(uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = rewardsTracker.process(gas);
		emit ProcessedRewardsTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }

    function claim() external {
		rewardsTracker.processAccount(payable(msg.sender), false);
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return rewardsTracker.getLastProcessedIndex();
    }

    function getNumberOfRewardsTokenHolders() external view returns(uint256) {
        return rewardsTracker.getNumberOfTokenHolders();
    }

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

    function sendETHtoTeamWallet(uint256 amount) private {
        swapTokensForEth(amount);
        uint256 balance = address(this).balance;

        teamWallet.transfer(balance);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityWallet,
            block.timestamp
        );
    }

    function swapForNotHolders(uint256 tokens) private {
        uint256 forLiquidtyWalletToken = tokens.mul(liquidityFee).div(notHoldersFee).div(2); 
        uint256 forTeamWallet = tokens.mul(teamFee).div(notHoldersFee); 

        uint256 balanceBeforeSwap = address(this).balance;
        
        swapTokensForEth(forLiquidtyWalletToken); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered
        uint256 ethReceivedFromSwap = address(this).balance.sub(balanceBeforeSwap);
        
        addLiquidity(forLiquidtyWalletToken, ethReceivedFromSwap); 
        sendETHtoTeamWallet(forTeamWallet); 

        emit SwapForNotHolders(forLiquidtyWalletToken, ethReceivedFromSwap, forLiquidtyWalletToken);
    }

    function swapToSendRewardsForHolders(uint256 tokens) private {
        swapTokensForEth(tokens);
        uint256 rewards = address(this).balance;
        (bool success,) = address(rewardsTracker).call{value: rewards}("");

        if(success) {
   	 		emit SendRewardsForHolders(tokens, rewards);
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        
        if( 
        	!swapping &&
            automatedMarketMakerPairs[to] && // sells only by detecting transfer to automated market maker pair
        	from != address(uniswapV2Router) && //router -> pair is removing liquidity which shouldn't have max
            !_isExcludedFromFees[to] && //no max for those excluded from fees
            from != liquidityWallet
        ) {
            require(amount <= maxSellTransactionAmount, "It exceeds the maxSellTransactionAmount.");
        }
        
		uint256 contractTokenBalance = balanceOf(address(this));
        
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;


        if(
            canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != liquidityWallet &&
            to != liquidityWallet
        ) {
            swapping = true;

            uint256 swapTokensForNotHolders = contractTokenBalance.mul(notHoldersFee).div(totalFees);
            swapForNotHolders(swapTokensForNotHolders);

            uint256 sellTokensForHolders = balanceOf(address(this));
            swapToSendRewardsForHolders(sellTokensForHolders);

            swapping = false;
        }

        bool takeFee =  !swapping; 

        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (useExcludeFromFeesUntilAtAmount && amount <= excludeFromFeesUntilAtAmount) {
            takeFee = false;
        }

        if(takeFee) {
        	uint256 fees = amount.mul(totalFees).div(100); 

            if(automatedMarketMakerPairs[to]) {
                fees = fees.mul(sellFeeIncreaseFactor).div(100); // 
            }

        	amount = amount.sub(fees); // Take default fees away here
            super._transfer(from, address(this), fees); // Send to this contract
        }

        super._transfer(from, to, amount);

        try rewardsTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try rewardsTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!swapping) {
	    	uint256 gas = gasForProcessing;

	    	try rewardsTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedRewardsTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	} 
	    	catch {

	    	}
        }
    }
}