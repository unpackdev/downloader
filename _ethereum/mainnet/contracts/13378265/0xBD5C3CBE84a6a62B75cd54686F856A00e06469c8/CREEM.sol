// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";
import "./CREEMDividendTracker.sol";

contract CREEM is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private swapping;

    CREEMDividendTracker public dividendTracker;
    address public peechToken;
    address public liquidityWallet;
    address public devWallet;
    address public rewardsWallet;
    address public immutable deadAddress = address(0x000000000000000000000000000000000000dEaD);
    uint256 public constant maxSellTransactionAmount = 10**7 * (10**18); // 10M
    uint256 public constant maxBuyTransactionAmount = 2 * 10**6 * (10**18); // 2M
    uint256 public constant swapTokensAtAmount = 2 * 10**6 * (10**18); //2M
    uint256 public constant devFee = 2;
    uint256 public constant rewardsFee = 4;
    uint256 public constant buybackFee = 4;
    uint256 public constant liquidityFee = 2;
    uint256 public constant burnFee = 2;
    uint256 public totalFees;

    // it can only be activated, once activated, it can't be disabled
    bool public isTradingEnabled;

    // it can only be disactivated once after the presale;
    bool public buyLimit = true;
    
    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;

    // addresses that can make transfers before presale is over
    mapping (address => bool) private canTransferBeforeTradingIsEnabled;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event ExcludeFromDividends(address indexed account);

    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    
    event ExcludeMultipleAccountsFromDividends(address[7] accounts);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);

    event DevWalletUpdated(address indexed newDevWallet, address indexed oldDevWallet);

    event RewardsWalletUpdated(address indexed newRewardsWallet, address indexed oldRewardsWallet);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SendDividends(
    	uint256 tokensSwapped,
    	uint256 amount
    );
    
    event burnTokens(
    	uint256 tokensSwapped
    );

    event DepositEthSendDividends(
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

    constructor(address _peechToken,
                address _liquidityWallet,
                address _devWallet,
                address _rewardsWallet) ERC20("CREEM", "CREEM") {
        peechToken = _peechToken;
        liquidityWallet = _liquidityWallet;
        devWallet = _devWallet;
        rewardsWallet = _rewardsWallet;
        totalFees = rewardsFee.add(liquidityFee).add(devFee).add(burnFee).add(buybackFee);
        dividendTracker = new CREEMDividendTracker();
        _mint(owner(), 10**9 * 10**uint(decimals()));
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        //  Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        dividendTracker.setPair(_uniswapV2Pair);
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        // exclude from receiving dividends
        excludeFromDividends(address(dividendTracker));
        excludeFromDividends(address(this));
        excludeFromDividends(owner());
        excludeFromDividends(address(_uniswapV2Router));
        excludeFromDividends(devWallet);
        excludeFromDividends(rewardsWallet);
        excludeFromDividends(liquidityWallet);
        // // exclude from paying fees or having max transaction amount
        excludeFromFees(liquidityWallet, true);
        excludeFromFees(devWallet, true);
        excludeFromFees(rewardsWallet, true);
        excludeFromFees(address(this), true);
        excludeFromFees(owner(), true);
        // // enable owner and fixed-sale wallet to send tokens before presales are over
        canTransferBeforeTradingIsEnabled[owner()] = true;
        canTransferBeforeTradingIsEnabled[0xF99baEc9220b02C6E34845259bA558E2f55576C5] = true;
    }
    receive() external payable {
  	}
    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "CREEM: The dividend tracker already has that address");
        CREEMDividendTracker newDividendTracker = CREEMDividendTracker(payable(newAddress));
        require(newDividendTracker.owner() == address(this), "CREEM: The new dividend tracker must be owned by the CREEM token contract");
        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));
        newDividendTracker.excludeFromDividends(devWallet);
        newDividendTracker.excludeFromDividends(rewardsWallet);
        newDividendTracker.excludeFromDividends(liquidityWallet);
        emit UpdateDividendTracker(newAddress, address(dividendTracker));
        dividendTracker = newDividendTracker;
    }
    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "CREEM: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "CREEM: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }
    function excludeFromDividends(address account) public onlyOwner {
        require(!dividendTracker.isExcludedFromDividends(account), "CREEM: Account is already excluded from dividends");
        dividendTracker.excludeFromDividends(account);
        emit ExcludeFromDividends(account);
    }
    function setPeech(address _newAddress) external onlyOwner {
        require(peechToken != _newAddress,"CREEM: peechToken has similar address!");
        peechToken = _newAddress;
    }
    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }
        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }
    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "CREEM: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "CREEM: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }
        emit SetAutomatedMarketMakerPair(pair, value);
    }
    function updateLiquidityWallet(address newLiquidityWallet) public onlyOwner {
        require(newLiquidityWallet != liquidityWallet, "CREEM: The liquidity wallet is already this address");
        excludeFromFees(newLiquidityWallet, true);
        emit LiquidityWalletUpdated(newLiquidityWallet, liquidityWallet);
        liquidityWallet = newLiquidityWallet;
    }
    function updateDevWallet(address newDevWallet) public onlyOwner {
        require(newDevWallet != devWallet, "CREEM: The development wallet is already this address");
        excludeFromFees(newDevWallet, true);
        emit DevWalletUpdated(newDevWallet, devWallet);
        devWallet = newDevWallet;
    }
    function updateRewardsWallet(address newRewardsWallet) public onlyOwner {
        require(newRewardsWallet != rewardsWallet, "CREEM: The development wallet is already this address");
        excludeFromFees(newRewardsWallet, true);
        emit RewardsWalletUpdated(newRewardsWallet, rewardsWallet);
        rewardsWallet = newRewardsWallet;
    }
    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }
    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }
    function isExcludedFromDividends(address account) public view returns(bool) { 
        return dividendTracker.isExcludedFromDividends(account);
    }
    function withdrawnDividendOf(address account) public view returns(uint256) {
    	return dividendTracker.withdrawnDividendOf(account);
  	}
	function dividendTokenBalanceOf(address account) public view returns (uint256) {
		return dividendTracker.balanceOf(account);
	}
    function getAccountDividendsInfo(address account)
        external view returns (
            address,
            int256,
            uint8,
            uint256) {
        return dividendTracker.getAccount(account);
    }
	function getAccountDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            uint8,
            uint256) {
    	return dividendTracker.getAccountAtIndex(index);
    }
    function minimumValueTier(uint8 _tier) public view returns(uint){
        return dividendTracker.minimumValueTier(_tier);
    }
    function minimumTier(uint8 _tier) public view returns(uint){
        return dividendTracker.minimumTier(_tier);
    }
    function minimumRewards(uint8 _tier) public view returns(uint){
        return dividendTracker.minimumRewards(_tier);
    }
    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }
    function activateTrading() external onlyOwner {
        require(!isTradingEnabled,"CREEM: trading has already been activated");
        isTradingEnabled = true;
    }
    function disableBuyLimit() external onlyOwner{
        require(buyLimit,"CREEM: buy limit already disactivated");
        buyLimit = false;
    }
    function shuffle() external onlyOwner{
        dividendTracker.shuffle();
    }
    // make sure that values are in wei
    function setTierRewards(uint tier1, uint tier2, uint tier3, uint tier4) external onlyOwner{
        dividendTracker.setTierRewards(tier1,tier2,tier3,tier4);
    }
    // make sure that values are in wei
    function setTierThreshold(uint tier1, uint tier2, uint tier3, uint tier4) external onlyOwner{
        dividendTracker.setTierThreshold(tier1,tier2,tier3,tier4);
    }
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        if(!isTradingEnabled) {
            require(canTransferBeforeTradingIsEnabled[from], "CREEM: This account cannot send tokens until trading is enabled");
        }
        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        if( 
        	!swapping &&
        	isTradingEnabled &&
            automatedMarketMakerPairs[to] && // sells only by detecting transfer to automated market maker pair
        	from != address(uniswapV2Router) && //router -> pair is removing liquidity which shouldn't have max
            !_isExcludedFromFees[to] //no max for those excluded from fees
        ) {
            require(amount <= maxSellTransactionAmount, "CREEM: Sell transfer amount exceeds the maxSellTransactionAmount.");
        }
        if( buyLimit &&
        	!swapping &&
        	isTradingEnabled &&
            automatedMarketMakerPairs[from] && // buy only by detecting transfer from automated market maker pair
        	to != address(uniswapV2Router) && //router -> pair is adding liquidity which shouldn't have max
            !_isExcludedFromFees[to] //no max for those excluded from fees
        ) {
            require(amount <= maxBuyTransactionAmount, "CREEM: Buy transfer amount exceeds the maxBuyTransactionAmount.");
        }
		uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        if(
            isTradingEnabled && 
            canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != liquidityWallet &&
            to != liquidityWallet
        ) {
            swapping = true;
            uint256 swapLiquidityTokens = contractTokenBalance.mul(liquidityFee).div(totalFees);
            swapAndLiquify(swapLiquidityTokens);
            uint256 swapDevTokens = contractTokenBalance.mul(devFee).div(totalFees);
            swapAndSend(devWallet,swapDevTokens);
            uint256 swapBuybackTokens = contractTokenBalance.mul(buybackFee).div(totalFees);
            swapAndBurn(swapBuybackTokens);
            uint256 swapBurnTokens = contractTokenBalance.mul(burnFee).div(totalFees);
            _burn(address(this),swapBurnTokens);
            uint256 swapDividendTokens = balanceOf(address(this));
            swapAndSend(rewardsWallet,swapDividendTokens);
            swapping = false;
        }
        bool takeFee = isTradingEnabled && !swapping;
        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
        if(takeFee && 
           (automatedMarketMakerPairs[from] ||
           automatedMarketMakerPairs[to])) {
        	uint256 fees = amount.mul(totalFees).div(100);
        	amount = amount.sub(fees);
            super._transfer(from, address(this), fees);
        }
        super._transfer(from, to, amount);
        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
    }
    function swapAndLiquify(uint256 tokens) private {
        // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);
        
        uint256 initialBalance = address(this).balance;
        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered
        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);
        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
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
    function swapTokensAndBurn(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = peechToken;
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            deadAddress,
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
            0,
            0,
            liquidityWallet,
            block.timestamp
        );
    }
    function swapAndSend(address wallet, uint256 tokens) private {
        swapTokensForEth(tokens);
        uint256 dividends = address(this).balance;
        (bool success,) = wallet.call{value: dividends}("");
        if(success) {
   	 		emit SendDividends(tokens, dividends);
        }
    }
    function swapAndBurn(uint256 tokens) private {
        swapTokensAndBurn(tokens);
   	 	emit burnTokens(tokens);
    }
}