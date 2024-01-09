// SPDX-License-Identifier: MIT

/* #Flocks (FLOCKS)
               
- Liquidity Generation 
- BTC as Rewards
- Marketing Wallet for Project Sustainability
- Customize fees taken to reward holders
- Customize fees to generate liquidty
- Maximum Total Fees -15

*/
pragma solidity 0.8.4;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

contract Flocks is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private swapping;

    FLOCKSDividendTracker public dividendTracker;

    address public constant deadWallet = 0x000000000000000000000000000000000000dEaD;
	
    address public _marketingWalletAddress = 0xCa700c8726fc8f4A84759f9c97433ff4531547A8;

    address public constant BTC = address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599); 

    uint256 public swapTokensAtAmount = 20000 * (1e18); // Default to 0.002% of the total supply
	
    uint256 public maxTxAmount = 5000000 * (1e18); //0.5% of total supply
    uint256 public minTxAmount = 20000 * (1e18);   //0.002% of total supply. Can't change below this value.
    uint256 public BTCRewardsFee = 4;
    uint256 public liquidityFee  = 3;
    uint256 public marketingFee  = 2;
    uint256 public totalFees = BTCRewardsFee.add(liquidityFee).add(marketingFee);

    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;

     // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;


    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SendDividends(
    	uint256 tokensSwapped,
    	uint256 amount
    );

    event ProcessedDividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );

    event marketWalletUpdate(
        address indexed marketWallet
    );

    event btcRewardUpdate(
        uint256 newReward
    );

    event liquidityFeeUpdate(
        uint256 newReward
    );

    event marketingFeeUpdate(
        uint256 newReward
    );

    constructor() ERC20("Flocks", "FLOCKS") {

    	dividendTracker = new FLOCKSDividendTracker();

    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);     
        
        // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(deadWallet);
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(_marketingWalletAddress, true);
        excludeFromFees(address(this), true);

        _mint(owner(), 1000000000 * (1e18));
    }

    receive() external payable {}

    function updateDividendTracker(address newAddress) external onlyOwner {
        require(newAddress != address(0), "FLOCKS: newAddress is a zero address");
        require(newAddress != address(dividendTracker), "FLOCKS: The dividend tracker already has that address");

        FLOCKSDividendTracker newDividendTracker = FLOCKSDividendTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "FLOCKS: The new dividend tracker must be owned by the FLOCKS token contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(deadWallet);
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }

    function updateUniswapV2Router(address newAddress) external onlyOwner {        
        require(newAddress != address(0), "FLOCKS: newAddress is a zero address");
        require(newAddress != address(uniswapV2Router), "FLOCKS: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "FLOCKS: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setMarketingWallet(address payable wallet) external onlyOwner{
        require(wallet != address(0), "FLOCKS: newAddress is a zero address");
        _marketingWalletAddress = wallet;

        emit marketWalletUpdate(wallet);
    }

    function setBTCRewardsFee(uint256 value) external onlyOwner{
        BTCRewardsFee = value;
        totalFees = BTCRewardsFee.add(liquidityFee).add(marketingFee);
        require(totalFees <= 15, "Total fee is over 15%");

        emit btcRewardUpdate(value);
    }

    function setLiquiditFee(uint256 value) external onlyOwner{
        liquidityFee = value;
        totalFees = BTCRewardsFee.add(liquidityFee).add(marketingFee);
        require(totalFees <= 15, "Total fee is over 15%");

        emit liquidityFeeUpdate(value);
    }

    function setMarketingFee(uint256 value) external onlyOwner{
        marketingFee = value;
        totalFees = BTCRewardsFee.add(liquidityFee).add(marketingFee);
        require(totalFees <= 15, "Total fee is over 15%");
        emit marketingFeeUpdate(value);
    }
	
    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != address(0), "FLOCKS: newAddress is a zero address");
        require(pair != uniswapV2Pair, "FLOCKS: The PanCakeSwap pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }
    
    function setMaxTxPercent(uint256 _maxTxPercent) external onlyOwner() {
        require(minTxAmount <= _maxTxPercent, "Max Tx Amount can't set below 0.002% of total supply");
        maxTxAmount = _maxTxPercent;
    }
	
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "FLOCKS: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }


    function updateGasForProcessing(uint256 newValue) external onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "FLOCKS: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "FLOCKS: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    function getClaimWait() external view returns(uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) external view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account) external view returns(uint256) {
    	return dividendTracker.withdrawableDividendOf(account);
  	}

	function dividendTokenBalanceOf(address account) external view returns (uint256) {
		return dividendTracker.balanceOf(account);
	}

    function minimumTokenBalanceForDividends() public view returns (uint256) {
        return dividendTracker.minimumTokenBalanceForDividends();
    }

	function excludeFromDividends(address account) external onlyOwner{
	    dividendTracker.excludeFromDividends(account);
	}

    function setMinimumTokenBalanceForDividends(uint256 _minimumTokenBalanceForDividends) public onlyOwner {
        dividendTracker.setMinimumTokenBalanceForDividends(_minimumTokenBalanceForDividends);
    }

    function withdrawLeftOver() external onlyOwner {
        payable(_marketingWalletAddress).transfer(address(this).balance);
    }

    function getAccountDividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return dividendTracker.getAccount(account);
    }

	function getAccountDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	return dividendTracker.getAccountAtIndex(index);
    }

	function processDividendTracker(uint256 gas) external {
		(uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }

    function claim() external {
		dividendTracker.processAccount(payable(msg.sender), false);
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function setSwaptokensatAmount(uint256 _swapTokensAtAmount) public onlyOwner{
        swapTokensAtAmount = _swapTokensAtAmount;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        if(from != owner() && to != owner()){
            require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }
        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

		uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if( canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != owner() &&
            to != owner()
        ) {
            swapping = true;

            uint256 marketingTokens = contractTokenBalance.mul(marketingFee).div(totalFees);
            swapAndSendToFee(marketingTokens);

            uint256 swapTokens = contractTokenBalance.mul(liquidityFee).div(totalFees);
            swapAndLiquify(swapTokens);

            uint256 sellTokens = balanceOf(address(this));
            swapAndSendDividends(sellTokens);

            swapping = false;
        }


        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
		
        if(takeFee) {
        	uint256 fees = amount.mul(totalFees).div(100);
        	amount = amount.sub(fees);
            super._transfer(from, address(this), fees);
        }
		
        super._transfer(from, to, amount);

        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!swapping) {
	    	uint256 gas = gasForProcessing;

	    	try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	}
	    	catch {

	    	}
        }
    }

    function swapAndSendToFee(uint256 tokens) private {
        uint256 initialBTCBalance = IERC20(BTC).balanceOf(address(this));
        swapTokensForBTC(tokens);
        uint256 newBalance = (IERC20(BTC).balanceOf(address(this))).sub(initialBTCBalance);
        IERC20(BTC).transfer(_marketingWalletAddress, newBalance);
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        uint256 initialBalance = address(this).balance;
		
        swapTokensForEth(half);
		
        uint256 newBalance = address(this).balance.sub(initialBalance);
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }


    function swapTokensForEth(uint256 tokenAmount) private {
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

    function swapTokensForBTC(uint256 tokenAmount) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = BTC;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );

    }

    function swapAndSendDividends(uint256 tokens) private{
        swapTokensForBTC(tokens);
        uint256 dividends = IERC20(BTC).balanceOf(address(this));
        bool success = IERC20(BTC).transfer(address(dividendTracker), dividends);
		
        if (success) {
            dividendTracker.distributeBTCDividends(dividends);
            emit SendDividends(tokens, dividends);
        }
    }
}

contract FLOCKSDividendTracker is Ownable, DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;
    uint256 public maxEditableTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() DividendPayingToken("FLOCKS_Dividen_Tracker", "FLOCKS_Dividend_Tracker") {
    	claimWait = 3600;
        minimumTokenBalanceForDividends = 100000 * (1e18); //Default value 100000 tokens
        maxEditableTokenBalanceForDividends = 200000 * (1e18); //0.02% of total supply.  Owner can't change beyond this value.
    }

    function _transfer(address, address, uint256) internal override {
        require(false, "FLOCKS_Dividend_Tracker: No transfers allowed");
    }
	
    function withdrawDividend() public override {
        require(false, "FLOCKS_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main FLOCKS contract.");
    }

    function setMinimumTokenBalanceForDividends(uint256 _minimumTokenBalanceForDividends) public onlyOwner {
        require(_minimumTokenBalanceForDividends <= maxEditableTokenBalanceForDividends, "Minimum Token Blance For Dividends Can't set above 0.01% of total supply");
        minimumTokenBalanceForDividends = _minimumTokenBalanceForDividends;
    }

    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account], "Flocks: account is already excluded");
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "FLOCKS_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "FLOCKS_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }
	
    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable) {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ? tokenHoldersMap.keys.length.sub(lastProcessedIndex) : 0;
                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }


        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ? lastClaimTime.add(claimWait) : 0;
        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ? nextClaimTime.sub(block.timestamp) : 0;
    }

    function getAccountAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	if(index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
    	if(lastClaimTime > block.timestamp)  {
    		return false;
    	}

    	return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
    	if(excludedFromDividends[account]) {
    		return;
    	}

    	if(newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
    		tokenHoldersMap.set(account, newBalance);
    	}
    	else {
            _setBalance(account, 0);
    		tokenHoldersMap.remove(account);
    	}

    	processAccount(account, true);
    }

    function process(uint256 gas) external returns (uint256, uint256, uint256) {
    	uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

    	if(numberOfTokenHolders == 0) {
    		return (0, 0, lastProcessedIndex);
    	}

    	uint256 _lastProcessedIndex = lastProcessedIndex;

    	uint256 gasUsed = 0;

    	uint256 gasLeft = gasleft();

    	uint256 iterations = 0;
    	uint256 claims = 0;

    	while(gasUsed < gas && iterations < numberOfTokenHolders) {
    		_lastProcessedIndex++;

    		if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
    			_lastProcessedIndex = 0;
    		}

    		address account = tokenHoldersMap.keys[_lastProcessedIndex];

    		if(canAutoClaim(lastClaimTimes[account])) {
    			if(processAccount(payable(account), true)) {
    				claims++;
    			}
    		}

    		iterations++;

    		uint256 newGasLeft = gasleft();

    		if(gasLeft > newGasLeft) {
    			gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
    		}

    		gasLeft = newGasLeft;
    	}

    	lastProcessedIndex = _lastProcessedIndex;

    	return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

    	if(amount > 0) {
    		lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
    		return true;
    	}

    	return false;
    }
}