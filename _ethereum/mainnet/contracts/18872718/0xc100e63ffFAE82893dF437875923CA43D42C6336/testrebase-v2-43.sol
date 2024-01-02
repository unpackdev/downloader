// SPDX-License-Identifier: MIT
/**

######   #######  ######        ##   #####   #######       ##    ####   
#######  #######  #######      ###  #######  #######      ###    ####   
      #                 #        #                          #           
######   ####     ######      ####  ######   ####        ####     ##    
## ##    ##       #    ##    #####       ##  ##         #####     ##    
##  ##   #######  #######   ##  ##  #######  #######   ##  ##    ####   
##   ##  #######  ######   ##   ##   #####   #######  ##   ##    ####   

Welcome to RAI - Rebase AI - The first AI controlled Rebase Token

Not just a rebase token, the first step in the native integration of
AI and blockchain technology!

RAI is building an AI native and secured Layer 1 blockchain.

Meet RAI at :

website: https://iamrai.xyz
telegram: https://t.me/iamraixyz
Twitter/X: https://twitter.com/IamRAI_xyz

This is a V2 contract deployed to replace the original contract:
0x93e07dabda565f1a8513351038c1be23ba922b45
 */
pragma solidity ^0.8.12;

import "./testrebase-v2-30-library.sol";

contract RAI is ERC20, Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;


    //set manager and tax wallet address
    address public manager = 0xA7699dc9A4338e79ec60A2EF7cEBFe7785B2d567;
    address public taxWallet = 0xFF56db1A646f2EB995DD4bD78Aff05fE06dFBAdA;

    uint256 public rebasePercentage = 1;
    uint256 public transferTaxPercentage = 1;

    // Keep track of all holders
    EnumerableSet.AddressSet private allHolders;

    // Blacklist mapping
    mapping(address => bool) private blacklist;   

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public constant deadAddress = address(0xdead);
    address public WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    bool private swapping;

    uint256 public swapTokensAtAmount;

    // Enable or disable trading
    bool public tradingActive = false;
    bool public swapEnabled = true;
    bool public contractPaused = true;

    uint256 public buyTotalFees;
    uint256 public buyDevFee;
    uint256 public buyLiquidityFee;

    uint256 public sellTotalFees;
    uint256 public sellDevFee;
    uint256 public sellLiquidityFee;

    /******************/

    // exlcude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event AddedToBlacklist(address indexed account);
    event RemovedFromBlacklist(address indexed account);
    event ContractPaused(address indexed account, bool _paused);
    event TransferOnContractPaused(
        address indexed from,
        address indexed to,
        uint256 amount
    );

    event taxWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    constructor() ERC20("Rebase AI", "RAI") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), WETH9);
        excludeFromMaxTransaction(address(uniswapV2Pair), true);

        uint256 _buyDevFee = 1;
        uint256 _buyLiquidityFee = 0;

        uint256 _sellTaxFee = 1;
        uint256 _sellLiquidityFee = 0;

        uint256 totalSupply = 224150 * 10**18;

        swapTokensAtAmount = (totalSupply * 10) / 10000; // 0.05% swap wallet

        buyDevFee = _buyDevFee;
        buyLiquidityFee = _buyLiquidityFee;
        buyTotalFees = buyDevFee + buyLiquidityFee;

        sellDevFee = _sellTaxFee;
        sellLiquidityFee = _sellLiquidityFee;
        sellTotalFees = sellDevFee + sellLiquidityFee;

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(manager, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(address(0), true);

        excludeFromMaxTransaction(manager, true);
        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);
        excludeFromMaxTransaction(address(0), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(msg.sender, totalSupply);
        allHolders.add(msg.sender); // Add the initial owner to the set
    }

    receive() external payable {}

    // Modifier that allows only the owner or manager to call a function
    modifier onlyOwnerOrManager() {
        require(
            msg.sender == owner() || msg.sender == manager,
            "Not owner or manager"
        );
        _;
    }

    // Modifier to check if the address is not blacklisted
    modifier notBlacklisted(address _address) {
        require(!blacklist[_address], "Address is blacklisted");
        _;
    }

    // once enabled, can never be turned off
    function enableTrading() external onlyOwnerOrManager {
        tradingActive = true;
        swapEnabled = true;
    }

    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyOwnerOrManager {
        swapEnabled = enabled;
    }

    // only use to disable contract buys/sales if absolutely necessary (emergency use only)
    function updateContractPaused(bool _paused) external onlyOwnerOrManager {
        contractPaused = _paused;
        emit ContractPaused(msg.sender, _paused);
    }

    // Set or change the manager (onlyOwnerOrManager)
    function setManager(address _manager) external onlyOwnerOrManager {
        //remove old manager and add new manager to excludeFromFees

        excludeFromFees(_manager, true);
        excludeFromMaxTransaction(_manager, true);

        if (manager != owner()) {
            excludeFromFees(manager, false);
            excludeFromMaxTransaction(manager, false);
        }

        manager = _manager;
    }

    // Function to add an address to the blacklist and remove from allHolders (onlyOwnerOrManager)
    function addToBlacklist(address _address) external onlyOwnerOrManager {
        blacklist[_address] = true;

        // Check if the address is in allHolders and remove it
        allHolders.remove(_address);
        emit AddedToBlacklist(_address);
    }

    // Function to remove an address from the blacklist (onlyOwnerOrManager)
    function removeFromBlacklist(address _address) external onlyOwnerOrManager {
        blacklist[_address] = false;

        //add back to allholders if there is a balance of tokens
        if (balanceOf(_address) > 0) {
            allHolders.add(_address);
        }
        emit RemovedFromBlacklist(_address);
    }

    // Function to manually add an address to the allHolders array (onlyOwnerOrManager)
    function addToAllHolders(address _address) external onlyOwnerOrManager {
        require(!allHolders.contains(_address), "Address already a holder");
        require(!blacklist[_address], "Address is blacklisted");

        allHolders.add(_address);
    }

    // Update allHolders set when transfers occur
    function updateAllHolders(
        address from,
        address to,
        uint256 amount
    ) private {
        allHolders.add(to);
        if (from != address(this) && balanceOf(from).sub(amount) == 0) {
            allHolders.remove(from);
        }
    }

    // Function to update the transfer tax percentage (onlyOwnerOrManager)
    function setTransferTaxPercentage(uint256 _transferTaxPercentage)
        external
        onlyOwnerOrManager
    {
        transferTaxPercentage = _transferTaxPercentage;
    }

    // Function to update the rebase percentage (onlyOwnerOrManager)
    function setRebasePercentage(uint256 _rebasePercentage)
        external
        onlyOwnerOrManager
    {
        rebasePercentage = _rebasePercentage;
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount)
        external
        onlyOwnerOrManager
        returns (bool)
    {
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 5) / 1000,
            "Swap amount cannot be higher than 0.5% total supply."
        );
        swapTokensAtAmount = newAmount;
        return true;
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwnerOrManager
    {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function updateBuyFees(uint256 _devFee, uint256 _liquidityFee)
        external
        onlyOwnerOrManager
    {
        buyDevFee = _devFee;
        buyLiquidityFee = _liquidityFee;
        buyTotalFees = buyDevFee + buyLiquidityFee;
        require(buyTotalFees <= 10, "Must keep fees at 10% or less");
    }

    function updateSellFees(uint256 _devFee, uint256 _liquidityFee)
        external
        onlyOwnerOrManager
    {
        sellDevFee = _devFee;
        sellLiquidityFee = _liquidityFee;
        sellTotalFees = sellDevFee + sellLiquidityFee;
        require(sellTotalFees <= 15, "Must keep fees at 15% or less");
    }

    function excludeFromFees(address account, bool excluded)
        public
        onlyOwnerOrManager
    {
        _isExcludedFromFees[account] = excluded;
    }

    function updateTaxWallet(address newTaxWallet) external onlyOwnerOrManager {
        emit taxWalletUpdated(newTaxWallet, taxWallet);
        taxWallet = newTaxWallet;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function isBlacklisted(address account) public view returns (bool) {
        return blacklist[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override notBlacklisted(from) notBlacklisted(to) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        //do not allow transfers exepct from owner/manager/contract if contract is paused
        if (contractPaused) {
            emit TransferOnContractPaused(from, to, amount);
            require(
                _isExcludedFromFees[from] || _isExcludedFromFees[to],
                "Contract is Paused."
            );
            // Update allHolders set when transfers occur
            updateAllHolders(from, to, amount);
            super._transfer(from, to, amount);

            return;
        }

        if (!tradingActive && !_isExcludedFromFees[from]) {
            require(
                to != uniswapV2Pair || from != uniswapV2Pair,
                "Trading is not active."
            );
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            to == uniswapV2Pair &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        uint256 tokensForLiquidity = 0;
        uint256 tokensForDev = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // on sell
            if (to == uniswapV2Pair && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(100);
                tokensForLiquidity = (fees * sellLiquidityFee) / sellTotalFees;
                tokensForDev = (fees * sellDevFee) / sellTotalFees;
            }
            // on buy
            else if (from == uniswapV2Pair && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(100);
                tokensForLiquidity = (fees * buyLiquidityFee) / buyTotalFees;
                tokensForDev = (fees * buyDevFee) / buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
            if (tokensForLiquidity > 0) {
                super._transfer(
                    address(this),
                    uniswapV2Pair,
                    tokensForLiquidity
                );
            }

            amount -= fees;
        }

        // Update allHolders set when transfers occur
        updateAllHolders(from, to, amount);

        super._transfer(from, to, amount);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH9;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            taxWallet,
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        swapTokensForETH(contractBalance);
    }

    function _transferWithoutHolderUpdate(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        super._transfer(sender, recipient, amount);
    }

    // Function to trigger the rebase
    function rebase() external onlyOwnerOrManager {
        uint256 totalSupplyBefore = totalSupply();
        uint256 rebaseAmount = (totalSupplyBefore * rebasePercentage) / 100;

        // Increase total supply
        _mint(address(this), rebaseAmount);

        // Distribute the newly minted tokens to all existing holders, including the liquidity pool uniswapV2Pair
        for (uint256 i = 0; i < allHolders.length(); i++) {
            address account = allHolders.at(i);

            uint256 previousBalance = balanceOf(account);
            uint256 holderRebaseAmount = (previousBalance * rebasePercentage) /
                100;

            // Use _transferWithoutHolderUpdate to update the balance
            _transferWithoutHolderUpdate(
                address(this),
                account,
                holderRebaseAmount
            );
        }
    }
}
