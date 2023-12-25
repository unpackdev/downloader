pragma solidity ^0.8.17;

interface IUniswapV2Router02 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function WETH() external view returns (address);
    
    function factory() external view returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    // Add other functions as needed
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    // Add other functions as needed
}



//  ▄▄▄       █    ██  ██▀███   ▄▄▄          ▄████▄   ▒█████   ██▓ ███▄    █ 
// ▒████▄     ██  ▓██▒▓██ ▒ ██▒▒████▄       ▒██▀ ▀█  ▒██▒  ██▒▓██▒ ██ ▀█   █ 
// ▒██  ▀█▄  ▓██  ▒██░▓██ ░▄█ ▒▒██  ▀█▄     ▒▓█    ▄ ▒██░  ██▒▒██▒▓██  ▀█ ██▒
// ░██▄▄▄▄██ ▓▓█  ░██░▒██▀▀█▄  ░██▄▄▄▄██    ▒▓▓▄ ▄██▒▒██   ██░░██░▓██▒  ▐▌██▒
//  ▓█   ▓██▒▒▒█████▓ ░██▓ ▒██▒ ▓█   ▓██▒   ▒ ▓███▀ ░░ ████▓▒░░██░▒██░   ▓██░
//  ▒▒   ▓▒█░░▒▓▒ ▒ ▒ ░ ▒▓ ░▒▓░ ▒▒   ▓▒█░   ░ ░▒ ▒  ░░ ▒░▒░▒░ ░▓  ░ ▒░   ▒ ▒ 
//   ▒   ▒▒ ░░░▒░ ░ ░   ░▒ ░ ▒░  ▒   ▒▒ ░     ░  ▒     ░ ▒ ▒░  ▒ ░░ ░░   ░ ▒░
//   ░   ▒    ░░░ ░ ░   ░░   ░   ░   ▒      ░        ░ ░ ░ ▒   ▒ ░   ░   ░ ░ 
//       ░  ░   ░        ░           ░  ░   ░ ░          ░ ░   ░           ░ 
//                                          ░                                

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ContractMetadata.sol";

contract AURA is ERC20, Ownable, ContractMetadata {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;
    address public constant deadAddress = address(0xdead);

    bool private swapping;

    address public marketingWallet;
    address public revShareWallet;
    address public auraAccountWallet;

    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    bool public tradingActive = false;
    bool public swapEnabled = false;

    // Anti-bot and anti-whale mappings and variables
    mapping(address => bool) blacklisted;

    uint256 public buyTotalFees;
    uint256 public sellTotalFees;
	
	uint256 accountSharePerc;
	uint256 marketingSharePerc;
	uint256 revSharePerc;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedMaxTransactionAmount;
    mapping(address => bool) private automatedMarketMakerPairs;

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event marketingWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event revShareWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event auraAccountWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    constructor() ERC20("$AURA", "$AURA") Ownable() {
        uint256 totalSupply = 8_000_000 ether;

        uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        maxTransactionAmount = totalSupply;
        maxWallet = totalSupply;
        swapTokensAtAmount = (totalSupply * 5) / 10000;

        marketingWallet = address(0xc37683a890398B7e61b895Cf17e7A61842F46D05);
        revShareWallet = address(0x7d5A404A2472964420983Ec4B348749575142D2b);
        auraAccountWallet = address(0x9B265957bCC2E275d6b3657E9F5caC1a5C72024c);
		
		accountSharePerc = 40;
		marketingSharePerc = 40;
		revSharePerc = 20;

        buyTotalFees = 5;
        sellTotalFees = 5;

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(deadAddress, true);
        excludeFromFees(marketingWallet, true);
        excludeFromFees(revShareWallet, true);
        excludeFromFees(auraAccountWallet, true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(deadAddress, true);
        excludeFromMaxTransaction(address(uniswapV2Router), true);
        excludeFromMaxTransaction(marketingWallet, true);
        excludeFromMaxTransaction(revShareWallet, true);
        excludeFromMaxTransaction(auraAccountWallet, true);

        _mint(owner(), 8_000_000 ether);
    }

    receive() external payable {}

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
	
    function enableTrading() external onlyOwner 
	{
        require(!tradingActive, "Trading already active.");

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );
        _approve(address(this), address(uniswapV2Pair), type(uint256).max);
        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );

        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
        excludeFromMaxTransaction(address(uniswapV2Pair), true);

        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );

        maxTransactionAmount = (totalSupply() * 25) / 10000;
        maxWallet = (totalSupply() * 25) / 10000;

        tradingActive = true;
        swapEnabled = true;
    }

//Fallback in case we want to create the LP manually
    function noLiqEnableTrading() external onlyOwner
    {
        require(!tradingActive, "Trading already active.");

        maxTransactionAmount = (totalSupply() * 25) / 10000;
        maxWallet = (totalSupply() * 25) / 10000;

        tradingActive = true;
        swapEnabled = true;
    }

    function _canSetContractURI() internal view virtual override returns (bool) {
        // You can specify the logic for who can set the contract's metadata here
        // For example, you can restrict it to the contract owner
        return msg.sender == owner();
    }
    
//Emergency function in case we want to stop the automatic splitter
	function setSwapEnabled(bool _swapEnabled) external onlyOwner 
	{
		swapEnabled = _swapEnabled;
	}

    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner returns (bool)
    {
        swapTokensAtAmount = newAmount;
        return true;
    }
	
	function updateSplitPercentages(uint256 _accountSharePerc,uint256 _marketingSharePerc,uint256 _revSharePerc) external onlyOwner
	{
		accountSharePerc = _accountSharePerc;
		marketingSharePerc = _marketingSharePerc;
		revSharePerc = _revSharePerc;
	}

    function updateMaxWalletAndTxnAmount(uint256 newTxnNum, uint256 newMaxWalletNum) external onlyOwner 
	{
        require(
            newTxnNum >= ((totalSupply() * 5) / 1000),
            "ERC20: Cannot set maxTxn lower than 0.5%"
        );
        require(
            newMaxWalletNum >= ((totalSupply() * 5) / 1000),
            "ERC20: Cannot set maxWallet lower than 0.5%"
        );
        maxWallet = newMaxWalletNum;
        maxTransactionAmount = newTxnNum;
    }

    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner
    {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function updateMarketingWallet(address _marketingWallet) external onlyOwner
    {
        require(_marketingWallet != address(0), "ERC20: Address 0");
        address oldWallet = marketingWallet;
        marketingWallet = _marketingWallet;
        emit marketingWalletUpdated(marketingWallet, oldWallet);
    }

    function updateRevShareWallet(address _revShareWallet) external onlyOwner 
	{
        require(_revShareWallet != address(0), "ERC20: Address 0");
        address oldWallet = revShareWallet;
        revShareWallet = _revShareWallet;
        emit revShareWalletUpdated(revShareWallet, oldWallet);
    }

    function updateAuraAccountWallet(address _auraAccountWallet) external onlyOwner
    {
        require(_auraAccountWallet != address(0), "ERC20: Address 0");
        address oldWallet = auraAccountWallet;
        auraAccountWallet = _auraAccountWallet;
        emit auraAccountWalletUpdated(auraAccountWallet, oldWallet);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner 
	{
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function blacklist(address[] calldata accounts, bool value) public onlyOwner
    {
        for (uint256 i = 0; i < accounts.length; i++) 
		{
            if (
                (accounts[i] != uniswapV2Pair) &&
                (accounts[i] != address(uniswapV2Router)) &&
                (accounts[i] != address(this))
            ) blacklisted[accounts[i]] = value;
        }
    }

    function withdrawStuckETH() public onlyOwner 
	{
        bool success;
        (success, ) = address(msg.sender).call{value: address(this).balance}(
            ""
        );
    }

    function withdrawStuckTokens(address tkn) public onlyOwner 
	{
        require(IERC20(tkn).balanceOf(address(this)) > 0, "No tokens");
        uint256 amount = IERC20(tkn).balanceOf(address(this));
        IERC20(tkn).transfer(msg.sender, amount);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function isBlacklisted(address account) public view returns (bool) {
        return blacklisted[account];
    }

    function _transfer(address from, address to, uint256 amount) internal override 
	{
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!blacklisted[from], "ERC20: bot detected");
        require(!blacklisted[msg.sender], "ERC20: bot detected");
        require(!blacklisted[tx.origin], "ERC20: bot detected");

        if (amount == 0) 
		{
            super._transfer(from, to, 0);
            return;
        }

        if (from != owner() && to != owner() && to != address(0) && to != deadAddress && !swapping) 
		{
            if (!tradingActive) 
			{
                require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "ERC20: Trading is not active.");
            }

            //BUY Transaction
            if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) 
			{
                require(
                    amount <= maxTransactionAmount,
                    "ERC20: Buy transfer amount exceeds the maxTransactionAmount."
                );
                require(
                    amount + balanceOf(to) <= maxWallet,
                    "ERC20: Max wallet exceeded"
                );
            }
            //SELL Transaction
            else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) 
			{
                require(amount <= maxTransactionAmount, "ERC20: Sell transfer amount exceeds the maxTransactionAmount.");
            } 
			else if (!_isExcludedMaxTransactionAmount[to]) 
			{
                require(amount + balanceOf(to) <= maxWallet, "ERC20: Max wallet exceeded");
            }
        }

        bool canSwap = balanceOf(address(this)) >= swapTokensAtAmount;

        if (canSwap && swapEnabled && !swapping && !automatedMarketMakerPairs[from] && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) 
		{
            swapping = true;

            swapBack();

            swapping = false;
        }

        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;

        if (takeFee) 
		{
            // SELL Transaction
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) 
			{
                fees = amount.mul(sellTotalFees).div(100);
            }
            // BUY Transaction
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(100);
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapBack() private 
	{
		IERC20 erc20Token = IERC20(this);
		uint256 erc20Balance = erc20Token.balanceOf(address(this));
		require(erc20Balance > 0, "No tokens");
		
		uint256 tokensForAuraAccount = erc20Balance.div(100).mul(accountSharePerc);
		uint256 tokensForMarketing = erc20Balance.div(100).mul(marketingSharePerc);
		uint256 tokensForRevShare = erc20Balance.div(100).mul(revSharePerc);
		
		erc20Token.transfer(revShareWallet, tokensForRevShare);
		erc20Token.transfer(auraAccountWallet, tokensForAuraAccount);
		erc20Token.transfer(marketingWallet, tokensForMarketing);
   }
}