/**
 *Submitted for verification at Etherscan.io on 2023-08-17
*/

// SPDX-License-Identifier: MIT

//*************************************************************************************************//

// Website : https://hyperflxtoken.com/
// TG : https://t.me/hyperflxtoken

//*************************************************************************************************//

pragma solidity 0.8.19;
 
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
 
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {return payable(msg.sender);}
 
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string public _name;
    string public _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {return _name;}
    function symbol() public view virtual override returns (string memory) {return _symbol;}
    function decimals() public view virtual override returns (uint8) {return 18;}
    function totalSupply() public view virtual override returns (uint256) {return _totalSupply;}
    function balanceOf(address account) public view virtual override returns (uint256) {return _balances[account];}

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {return _allowances[owner][spender];}

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {_approve(sender, _msgSender(), currentAllowance - amount);}
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {_approve(_msgSender(), spender, currentAllowance - subtractedValue);}
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {_balances[sender] = senderBalance - amount;}
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _burn(address sender, uint256 amount) internal virtual {
        require(sender != address(0), "burn from the zero address");
 
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {_balances[sender] = senderBalance - amount;}
        _totalSupply -= amount;
        emit Transfer(sender, address(0), amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}



interface IDexRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);    
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
    function addLiquidityETH (address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

interface IDexFactory {function createPair(address tokenA, address tokenB) external returns (address pair);}
 
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
 
    function owner() public view virtual returns (address) {return _owner;}
 
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
 
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
 
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract SafeToken is Ownable {
    address payable public safeManager;
    event NewSafeManager (address indexed NewManager);
    constructor() {safeManager = payable(msg.sender);}
    
    function setSafeManager(address payable _safeManager) external onlyOwner {
        require(_safeManager != address(0), "Receiver is the zero address");
        safeManager = _safeManager;
        emit NewSafeManager (safeManager);
    }

    function withdraw(address _token, uint256 _amount) external { require(msg.sender == safeManager); IERC20(_token).transfer(safeManager, _amount);}
    function withdrawETH(uint256 _amount) external {require(msg.sender == safeManager); safeManager.transfer(_amount);}
}

contract Main is ERC20, Ownable, SafeToken {
 
    IDexRouter public DEXV2Router;
    address private immutable DEXV2Pair;
    address payable private MarketingWallet; 
    address private DeadWallet;
    address private DexRouter;
        
    bool private swapping;
    bool private swapAndLiquifyEnabled = true;
    bool public tradingEnabled = false;
    bool private JeetsFee = true;
    bool private JeetsBurn = true;
    bool private DelayOption = false;

    uint256 private marketingETHPortion = 0;

    uint256 private MaxSell;
    uint256 private MaxWallet;
    uint256 private SwapMin;
    uint256 private MaxSwap;
    uint256 private MaxTaxes;
    uint256 private MaxTokenToSwap;
    uint256 private maxSellTransactionAmount;
    uint256 private maxWalletAmount;
    uint256 private swapTokensAtAmount;
    uint8 private decimal;
    uint256 private InitialSupply;
    uint256 private DispatchSupply;
    uint256 private _liquidityUnlockTime = 0;
    uint256 private counter;
    uint256 private MinTime = 0;
    
    // Tax Fees
    uint256 private _LiquidityFee = 0;
    uint256 private _BurnFee = 0;
    uint256 private _MarketingFee= 2;
    uint256 private _Wallet2WalletFee = 0; // no wallet to wallet fee
    uint256 private _BuyFee = 2;
    uint256 private _SellFee = 0;
    uint8 private VminDiv = 1;
    uint8 private VmaxDiv = 15;
    uint8 private MaxJeetsFee = 30;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isWhitelisted;
    mapping (address => bool) private _isExcludedFromMaxTx;
    mapping (address => uint256) private LastTimeSell; 
    mapping (address => bool) public automatedMarketMakerPairs;
 
    event UpdateDEXV2Router(address indexed newAddress, address indexed oldAddress);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ETHReceived, uint256 tokensIntoLiqudity);
    event ExtendLiquidityLock(uint256 extendedLockTime);
    event NewDelay (bool delay, uint256 time);
    event NewLimits (uint256 maxWallet, uint256 maxSell, uint256 minswap, uint256 swapmax, uint256 maxtax);
    event NewFees (uint256 buy, uint256 Sell);
    event NewMarketingWallet (address indexed newMarketingWallet);
    event Launched (bool trading);
    event LPReleased (address indexed receiver, uint256 amount);
    event JeetTaxChanged (uint8 Maxdiv, uint8 Mindiv, uint8 Jeetsfee);
    event BuyBackTriggered(uint256 amount);
    
    constructor(string memory name_, string memory symbol_, uint8 decimal_, address marketing_, uint256 supply_, uint256 dispatch_, uint8 maxtaxes_) ERC20(name_, symbol_) {
    	
        MarketingWallet = payable(marketing_);
        DeadWallet = 0x000000000000000000000000000000000000dEaD;
        decimal = decimal_;
        InitialSupply = supply_*10**decimal;
        DispatchSupply = dispatch_*10**decimal;
        MaxSwap = supply_ * 1 / 100;
        MaxSell = supply_ * 4 / 100;
        MaxWallet = supply_ * 100 / 100;
        SwapMin = supply_ * 1 / 1000;
        MaxTokenToSwap = MaxSwap*10**decimal;
        maxSellTransactionAmount = MaxSell * 10**decimal;
        maxWalletAmount = MaxWallet * 10**decimal;
        swapTokensAtAmount = SwapMin * 10**decimal;
        MaxTaxes = maxtaxes_;
              
        // Create a DEX pair for this new token
        
        IDexRouter _dexRouter = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _DEXV2Pair = IDexFactory(_dexRouter.factory()).createPair(address(this), _dexRouter.WETH());
 
        DEXV2Router = _dexRouter;
        DEXV2Pair = _DEXV2Pair;
        _setAutomatedMarketMakerPair(_DEXV2Pair, true);

        _SellFee = _LiquidityFee + _MarketingFee + _BurnFee;//YY%

        // exclude from paying fees or having max transaction amount
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[DeadWallet] = true;
        _isExcludedFromFees[MarketingWallet] = true;
        _isExcludedFromFees[msg.sender] = true;
 
        // exclude from max tx
        _isExcludedFromMaxTx[address(this)] = true;
        _isExcludedFromMaxTx[DeadWallet] = true;
        _isExcludedFromMaxTx[MarketingWallet] = true;
        _isExcludedFromMaxTx[msg.sender] = true;

        // Whitelist
        _isWhitelisted[address(this)] = true;
        _isWhitelisted[DeadWallet] = true;
        _isWhitelisted[MarketingWallet] = true;
        _isWhitelisted[msg.sender] = true;
        
        //  _mint is an internal function in ERC20.sol that is only called here, and CANNOT be called ever again
        if(DispatchSupply == 0) {_mint(address(this), InitialSupply);} 
        else if (DispatchSupply == InitialSupply) {_mint(msg.sender, DispatchSupply);}
        else {
            _mint(msg.sender, DispatchSupply);
            _mint(address(this), InitialSupply - DispatchSupply);
        }
    }
 
    receive() external payable {}
    //******************************************************************************************************
    // Public functions
    //******************************************************************************************************
    function decimals() override public view returns (uint8) { return decimal; }
    function GetExclusions(address account) public view returns(bool MaxTx, bool Fees, bool Whitelist){return (_isExcludedFromMaxTx[account], _isExcludedFromFees[account], _isWhitelisted[account]);}
    function GetFees() public view returns(uint Buy, uint Sell, uint Wallet2Wallet, uint Liquidity, uint Marketing, uint Burn){return (_BuyFee, _SellFee, _Wallet2WalletFee, _LiquidityFee, _MarketingFee, _BurnFee);}
    function GetLimits() public view returns(uint256 SellMax, uint256 WalletMax, uint256 TaxMax, uint256 MinSwap, uint256 SwapMax, bool SwapLiq, bool ENtrading){return (MaxSell, MaxWallet, MaxTaxes, SwapMin, MaxSwap, swapAndLiquifyEnabled, tradingEnabled);}
    function GetDelay() public view returns (bool delayoption, uint256 mintime) {return (DelayOption, MinTime);}
    function GetContractAddresses() public view returns(address marketing, address Dead, address LP){return (address(MarketingWallet), address(DeadWallet), address(DEXV2Pair));}
    function GetJeetsTaxInfo() external view returns (bool jeetsfee, bool jeetsburn, uint vmaxdiv, uint vmindiv, uint maxjeetsfee) {return(JeetsFee, JeetsBurn, VmaxDiv, VminDiv, MaxJeetsFee);}
    function GetContractBalance() external view returns (uint256 marketingETH) {return(marketingETHPortion);}
    
    function GetSupplyInfo() public view returns (uint256 initialSupply, uint256 circulatingSupply, uint256 burntTokens) {
        uint256 supply = totalSupply ();
        uint256 tokensBurnt = InitialSupply - supply;
        return (InitialSupply, supply, tokensBurnt);
    }
        
    function getLiquidityUnlockTime() public view returns (uint256 Days, uint256 Hours, uint256 Minutes, uint256 Seconds) {
        if (block.timestamp < _liquidityUnlockTime){
            Days = (_liquidityUnlockTime - block.timestamp) / 86400;
            Hours = (_liquidityUnlockTime - block.timestamp - Days * 86400) / 3600;
            Minutes = (_liquidityUnlockTime - block.timestamp - Days * 86400 - Hours * 3600 ) / 60;
            Seconds = _liquidityUnlockTime - block.timestamp - Days * 86400 - Hours * 3600 - Minutes * 60;
            return (Days, Hours, Minutes, Seconds);
        } 
        return (0, 0, 0, 0);
    }
    //******************************************************************************************************
    // Write OnlyOwners functions
    //******************************************************************************************************
 
    function buyBackBurn(uint256 amountInWei) external {
        require(amountInWei <= 10 ether, "May not buy more than 10 ETH in a single buy to reduce sandwich attacks");
        require(msg.sender == safeManager);

        address[] memory path = new address[](2);
        path[0] = DEXV2Router.WETH();
        path[1] = address(this);

        // make the swap
        DEXV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountInWei}(0, path, address(DeadWallet), block.timestamp);
        emit BuyBackTriggered(amountInWei);
    }

    function Airdrop(address[] memory wallets, uint256[] memory amountsInTokens) external onlyOwner {
        require(wallets.length == amountsInTokens.length, "arrays must be the same length");
        require(wallets.length < 600, "Can only airdrop 600 wallets per txn due to gas limits"); // allows for airdrop + launch at the same exact time, reducing delays and reducing sniper input.
        for(uint256 i = 0; i < wallets.length; i++){
            address wallet = wallets[i];
            uint256 amount = amountsInTokens[i] * 10**decimal;
            super._transfer(msg.sender, wallet, amount);
        }
    }

    function setProjectWallet (address payable _newMarketingWallet) external onlyOwner {
        if (_newMarketingWallet != MarketingWallet) {
            _isExcludedFromFees[MarketingWallet] = false;
            _isExcludedFromMaxTx[MarketingWallet] = false;
            _isWhitelisted[MarketingWallet] = false;
               
            _isExcludedFromFees[_newMarketingWallet] = true;
            _isExcludedFromMaxTx[_newMarketingWallet] = true;
            _isWhitelisted[_newMarketingWallet] = true;
  	        MarketingWallet = _newMarketingWallet;
        }
        emit NewMarketingWallet (_newMarketingWallet);
    }
        
    function SetDelay (bool delayoption, uint256 mintime) external onlyOwner {
        require(mintime <= 8640, "MinTime Can't be more than a Day" );
        MinTime = mintime;
        DelayOption = delayoption;
        emit NewDelay (delayoption, mintime);
    }
    
    function SetLimits(uint256 _maxWallet, uint256 _maxSell, uint256 _minswap, uint256 _swapmax, uint256 MaxTax, bool _swapAndLiquifyEnabled) external onlyOwner {
        uint256 supply = totalSupply ();
        require(_maxWallet * 10**decimal >= supply / 100 && _maxWallet * 10**decimal <= supply, "MawWallet must be between totalsupply and 1% of totalsupply");
        require(_maxSell * 10**decimal >= supply / 1000 && _maxSell * 10**decimal <= supply, "MawSell must be between totalsupply and 0.1% of totalsupply" );
        require(_minswap * 10**decimal >= supply / 10000 && _minswap <= _swapmax / 2, "MinSwap must be between maxswap/2 and 0.01% of totalsupply" );
        require(MaxTax >= 1 && MaxTax <= 25, "Max Tax must be updated to between 1 and 25 percent");
        require(_swapmax >= _minswap*2 && _swapmax * 10**decimal <= supply, "MaxSwap must be between totalsupply and SwapMin x 2" );

        MaxSwap = _swapmax;
        MaxTokenToSwap = MaxSwap * 10**decimal;
        MaxWallet = _maxWallet;
        maxWalletAmount = MaxWallet * 10**decimal;
        MaxSell = _maxSell;
        maxSellTransactionAmount = MaxSell * 10**decimal;
        SwapMin = _minswap;
        swapTokensAtAmount = SwapMin * 10**decimal;
        MaxTaxes = MaxTax; 
        swapAndLiquifyEnabled = _swapAndLiquifyEnabled;
        emit NewLimits (_maxWallet, _maxSell, _minswap, _swapmax, MaxTax);
        emit SwapAndLiquifyEnabledUpdated(_swapAndLiquifyEnabled);
    }
  
    function SetTaxes(uint256 newBuyTax, uint256 wallet2walletfee, uint256 newLiquidityTax, uint256 newBurnTax, uint256 newMarketingTax) external onlyOwner() {
        require(newBuyTax <= MaxTaxes && newBuyTax >= newBurnTax, "Total Tax can't exceed MaxTaxes. or be lower than burn tax");
        uint256 TransferTax = newMarketingTax;
        require(TransferTax + newLiquidityTax + newBurnTax <= MaxTaxes, "Total Tax can't exceed MaxTaxes.");
        require(newMarketingTax >= 0 && newBuyTax >= 0 && newLiquidityTax >= 0 && newBurnTax >= 0,"No tax can be negative");
        if(wallet2walletfee != 0){require(wallet2walletfee >= _BurnFee && wallet2walletfee <= MaxTaxes, "Wallet 2 Wallet Tax must be updated to between burn tax and 25 percent");}
        
        _BuyFee = newBuyTax;
        _Wallet2WalletFee = wallet2walletfee;
        _BurnFee = newBurnTax;
        _LiquidityFee = newLiquidityTax;
        _MarketingFee = newMarketingTax;
        _SellFee = _LiquidityFee + _MarketingFee + _BurnFee;

        emit NewFees (newBuyTax, _SellFee);
    } 
    
    function updateDEXV2Router(address newAddress) external onlyOwner {
        require(newAddress != address(DEXV2Router), "The router already has that address");
        emit UpdateDEXV2Router(newAddress, address(DEXV2Router));
        DEXV2Router = IDexRouter(newAddress);
    }
 
    function SetExclusions (address account, bool Fee, bool MaxTx, bool WhiteList) external onlyOwner {
        require (_isExcludedFromFees[account] != Fee, "account already set");
        _isExcludedFromFees[account] = Fee;
        _isExcludedFromMaxTx[account] = MaxTx;
        _isWhitelisted[account] = WhiteList;
        emit ExcludeFromFees (account, Fee);
    }    
    
    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != DEXV2Pair, "The Market pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }
 
	function ExtendLockTime(uint256 newdays, uint256 newhours) external onlyOwner {
        uint256 lockTimeInSeconds = newdays*86400 + newhours*3600;
        if (_liquidityUnlockTime < block.timestamp) _liquidityUnlockTime = block.timestamp;
	    setUnlockTime(lockTimeInSeconds + _liquidityUnlockTime);
        emit ExtendLiquidityLock(lockTimeInSeconds);
    }

    function Launch (uint256 Blocks, uint256 lockTimeInDays, uint256 lockTimeInHours) external onlyOwner {
        require (tradingEnabled == false, "can only launch once");
        require(Blocks <= 40, "Not more than 2mn");
        if (address(this).balance == 0) 
        {
            tradingEnabled = true;
            counter = block.number + Blocks;
        } else 
        {
            uint256 lockTimeInSeconds = lockTimeInDays*86400 + lockTimeInHours*3600;
            _liquidityUnlockTime = block.timestamp + lockTimeInSeconds;
            addLiquidity (balanceOf(address(this)), address(this).balance);
            tradingEnabled = true;
            counter = block.number + Blocks;
        }
        emit Launched (tradingEnabled);
    }

    function ReleaseLP() external onlyOwner {
        require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");
        IERC20 liquidityToken = IERC20(DEXV2Pair);
        uint256 amount = liquidityToken.balanceOf(address(this));
        liquidityToken.transfer(msg.sender, amount);
        emit LPReleased (msg.sender, amount);
    }

    function SetJeetsTax(bool jeetsfee, bool jeetsburn, uint8 vmaxdiv, uint8 vmindiv, uint8 maxjeetsfee)  external {
        require(msg.sender == safeManager);
        require (vmaxdiv >= 10 && vmaxdiv <= 40, "cannot set Vmax outside 10%/40% ratio");
        require (vmindiv >= 1 && vmindiv <= 10, "cannot set Vmin outside 1%/10% ratio");
        require (maxjeetsfee >= 1 && maxjeetsfee <= 20, "max jeets fee must be betwwen 1% and 20%");
        JeetsFee = jeetsfee;
        JeetsBurn = jeetsburn;
        VmaxDiv = vmaxdiv;
        VminDiv = vmindiv;
        MaxJeetsFee = maxjeetsfee;
        emit JeetTaxChanged (vmaxdiv, vmindiv, maxjeetsfee);
    }
    //******************************************************************************************************
    // Internal functions
    //******************************************************************************************************
    function _setAutomatedMarketMakerPair(address pair, bool value) internal {
        require(automatedMarketMakerPairs[pair] != value, "Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }
    
    function takeFee(address from, address to, uint256 amount) internal returns (uint256) {
        uint256 fees = 0; // no wallet to wallet tax
        uint256 burntaxamount = 0; // no wallet to wallet tax
        uint256 extraTax = 0;
        
        if (automatedMarketMakerPairs[from]) {                   // buy tax applied if buy
            if (tradingEnabled && block.number < counter && !_isWhitelisted[to] && automatedMarketMakerPairs[from]) {
                fees = amount * 99 / 100;
                burntaxamount = amount * 99 / 100;
            } else if (_BuyFee != 0) {
                fees = amount * _BuyFee / 100;  // total fee amount
                burntaxamount=amount * _BurnFee / 100;    // burn amount aside
            }                   
        } else if(automatedMarketMakerPairs[to]) {          // sell tax applied if sell
            if (JeetsFee && !_isWhitelisted[from]){ // Jeets extra Fee against massive dumpers
                extraTax = JeetsSellTax(amount);
                if (extraTax > 0) {
                    if (JeetsBurn) {burntaxamount += extraTax;} 
                    fees += extraTax;
                }
            }
            if(_SellFee != 0) {
                fees += amount * _SellFee / 100; // total fee amount
                burntaxamount+=amount * _BurnFee / 100;    // burn amount aside
            }
        } else if(!automatedMarketMakerPairs[from] && !automatedMarketMakerPairs[to] && _Wallet2WalletFee != 0) {
            fees = amount * _Wallet2WalletFee / 100;
            burntaxamount=amount * _BurnFee / 100;    // burn amount aside      
        } 
        fees -= burntaxamount;    // fee is total amount minus burn
        
        if (burntaxamount != 0) {super._burn(from, burntaxamount);}    // burn amount 
        if(fees > 0) {super._transfer(from, address(this), fees);}
        return amount - fees - burntaxamount;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "transfer from the zero address");
        require(to != address(0), "transfer to the zero address");

        if(amount == 0) {return;}
        
        // preparation of launch LP and token dispatch allowed even if trading not allowed
        if(!tradingEnabled) {require(_isWhitelisted[from], "Trading not allowed yet");}

        if(!_isWhitelisted[to]){if(to != address(this) && to != DeadWallet){require((balanceOf(to) + amount) <= maxWalletAmount, "wallet amount exceed maxWalletAmount");}}
        if(automatedMarketMakerPairs[to] && (!_isExcludedFromMaxTx[from]) && (!_isExcludedFromMaxTx[to])){require(amount <= maxSellTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");}

        if (DelayOption && !_isWhitelisted[from] && automatedMarketMakerPairs[to]) {
            require( LastTimeSell[from] + MinTime <= block.number, "Trying to sell too often!");
            LastTimeSell[from] = block.number;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        if(contractTokenBalance >= MaxTokenToSwap){contractTokenBalance = MaxTokenToSwap;}
         // Can Swap on sell only
        if (swapAndLiquifyEnabled && canSwap && !swapping && !automatedMarketMakerPairs[from] && !_isWhitelisted[from] && !_isWhitelisted[to] &&  (_SellFee - _BurnFee) != 0 ) {
            swapping = true;
            swapAndLiquify(contractTokenBalance);
            swapping = false;
        }

        uint256 amountToSend = amount;
        if(!_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {amountToSend = takeFee(from, to, amount);}
        if(to == DeadWallet) {super._burn(from,amountToSend);}    // if destination address is Deadwallet, burn amount 
        else if(to != DeadWallet) {super._transfer(from, to, amountToSend);}
    }

    function swapAndLiquify(uint256 contractTokenBalance) private {
        uint256 NoRewardFees = _SellFee - _BurnFee;
        uint256 initialBalance = address(this).balance;
        
        uint256 half = contractTokenBalance * _LiquidityFee / 2 / (_SellFee - _BurnFee);
        
        uint256 swapTokens = (contractTokenBalance * NoRewardFees / (_SellFee - _BurnFee)) - half;
        swapTokensForETH(swapTokens);
        uint256 ETHBalance = address(this).balance - initialBalance;

        uint256 liquidityETHPortion = (ETHBalance * _LiquidityFee / 2) / (NoRewardFees - (_LiquidityFee / 2));
        marketingETHPortion += (ETHBalance * _MarketingFee) / (NoRewardFees - (_LiquidityFee / 2));
        
        if(_LiquidityFee != 0) {
            addLiquidity(half, liquidityETHPortion);
            emit SwapAndLiquify(half, liquidityETHPortion, half);
        }  
        if(marketingETHPortion != 0) {
            MarketingWallet.transfer(marketingETHPortion);
            marketingETHPortion = 0;
        }
    }
 
    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        uint256 Allowance = allowance(address(this), address(DEXV2Router)) + tokenAmount;
        _approve(address(this), address(DEXV2Router), Allowance);
        DEXV2Router.addLiquidityETH{value: ETHAmount}(address(this), tokenAmount, 0, 0, address(this), block.timestamp);
    }
 
    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = DEXV2Router.WETH();
        _approve(address(this), address(DEXV2Router), tokenAmount);
        DEXV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function setUnlockTime(uint256 newUnlockTime) private {
        // require new unlock time to be longer than old one
        require(newUnlockTime > _liquidityUnlockTime);
        _liquidityUnlockTime = newUnlockTime;
    }

    function JeetsSellTax (uint256 amount) internal view returns (uint256) {
        uint256 value = balanceOf(DEXV2Pair);
        uint256 vMin = value * VminDiv / 100;
        uint256 vMax = value * VmaxDiv / 100;
        if (amount <= vMin) return amount = 0;
        if (amount > vMax) return amount * MaxJeetsFee / 100;
        return (((amount-vMin) * MaxJeetsFee * amount) / (vMax-vMin)) / 100;
    }
}

contract HYPERFLXTOKEN is Main {

    constructor() Main(
        "HYPERFLXTOKEN",       // Name
        "HYFX",        // Symbol
        18,                  // Decimal
        0x8e210528fCF50e538bfeD58af32c21384a7240ab,     // Marketing address
        250_000_000_000,      // Initial Supply
        250_000_000_000,       // Dispa&tch Supply
        10     // Max Tax
        ) {}
}