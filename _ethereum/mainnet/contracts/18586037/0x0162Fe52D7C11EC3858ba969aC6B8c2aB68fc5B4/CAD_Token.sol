// SPDX-License-Identifier: MIT
//????????????????????????????????????????????????????????????????????
//????????????????????????????????????????????????????????????????????
//????????????????????????????????????????????????????????????????????
//????????????????????????????????????????????????????????????????????
//????????????????????????????????????????????????????????????????????
//????????????????????????????????????????????????????????????????????

pragma solidity ^0.8.0;

//OPENZEPPELIN IMPORTS
import "./Context.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Pausable.sol";
//UNISWAP IMPORTS
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";
    
contract RewardWallet {
    constructor() {}
    }

contract CAD_Token is Context, IERC20, ReentrancyGuard, Ownable, Pausable {	
    using Address for address;

//EVENTS
    event MaxWalletSizeChanged(uint256 newMaxWalletSize);
    event ExemptFromMaxWalletSizeChanged(address indexed account, bool isExempt);

    event RewardFeeUpdated(uint256 newFee);
    event StakingFeeUpdated(uint256 newFee);
    event MarketingFeeUpdated(uint256 newFee);
    event LiquidityFeeUpdated(uint256 newFee);
    event DevelopmentFeeUpdated(uint256 newFee);
    event SellRewardFeeUpdated(uint256 newFee);
    event SellStakingFeeUpdated(uint256 newFee);
    event SellMarketingFeeUpdated(uint256 newFee);
    event SellLiquidityFeeUpdated(uint256 newFee);
    event SellDevelopmentFeeUpdated(uint256 newFee);

    event ExcludedFromFee(address indexed account);
    event IncludedInFee(address indexed account);
    event ExcludedFromReward(address indexed account);
    
    event SwapCallerFeeUpdated(uint256 newFee);

//TOKEN SPECIFICATIONS
    uint256 private _totalSupply = 100e12 * 10**_decimals;
    string private constant _name = "CAD Token";
    string private constant _symbol = "CAD";
    uint8 private constant _decimals = 18;

//MAPPING
    mapping(address => uint256) internal _reflectionBalance;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    mapping(address => bool) internal isExcludedFromFee;
    mapping(address => bool) internal _isExcluded;
    mapping(address => bool) private _isExemptFromMaxWalletSize;
    address[] internal _excluded;

    uint256 private constant Maximum = ~uint256(0);
    uint256 internal _reflectionTotal = (Maximum - (Maximum % _totalSupply));

//FEE SPECIFICATIONS
    uint256 public constant _feeDecimal = 2;

    uint256 public _rewardFee = 0; // 0%
    uint256 public _stakingFee = 100; // 1%
    uint256 public _marketingFee = 100; // 1% 
    uint256 public _liquidityFee = 100; // 1%
    uint256 public _developementFee = 100; // 1%

    uint256 public sell_rewardFee =0; // 0%
    uint256 public sell_stakingFee = 100; // 1%
    uint256 public sell_marketingFee = 200; // 2% 
    uint256 public sell_liquidityFee = 250; // 2,5%
    uint256 public sell_developementFee = 200; // 2%


    uint256 public _rewardFeeTotal;	
    uint256 public _marketingFeeTotal;
    uint256 public _liquidityFeeTotal;
    uint256 public _swapCallerFee = 100e9 * 10**_decimals;

//MINIMAL AND MAXIMAL AMOUNT OF TOKENS ALLOWED TO TRANSFER
    uint256 public _maxWalletSize = 20e9 * 10**_decimals;
    uint256 public minTokensBeforeSwap = 100e3 * 10**_decimals; 
    uint256 public minTokenBeforeReward = 100e6 * 10**_decimals; 
//UNISWAP IUniswapV2Router02    
    IUniswapV2Router02 public uniswapRouter;
    address public uniswapPair;
    bool internal inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    bool public swap;
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped,uint256 ethReceived, uint256 tokensIntoLiqudity);
//NAMES WALLETS
    address public rewardWallet;
    address public initialOwner = msg.sender;
    address public balancerWallet = 0xaF47D770b66EEda194Fa69e4Db980D780F98128a;
    address public marketingWallet = 0xDF668Bf2CE79bB2541969Bad62624A6baEae2526;
    address public developmentWallet = 0x0CffbC0844ff978089752Fa805a21d80345D91aE;
    address public stakingWallet = 0x9d8aD95a5771D8f085C2b0543e1D2F13De165897;
//MODIFIERS
    modifier lockTheSwap {
	    inSwapAndLiquify = true;
	    _;
    	inSwapAndLiquify = false;
    }
//COOLDOWN
    mapping (address => uint256) private _lastTransferTime;
    uint256 private constant MINIMUM_COOLDOWN_TIME = 2 seconds;
    
constructor() Ownable(initialOwner) {
    // Initiate Reward Wallet
    rewardWallet = address(new RewardWallet());

    // Uniswap Router setup
    // Uniswap Sepolia router: 0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008
    // Uniswap Mainnet router: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    uniswapPair = IUniswapV2Factory(uniswapRouter.factory()).createPair(address(this), uniswapRouter.WETH());

    // Fee Excludes
    isExcludedFromFee[_msgSender()] = true;
    isExcludedFromFee[address(this)] = true;

    // Reflection Balance
    _reflectionBalance[owner()] = _reflectionTotal;

    // Emit Transfer event for initial token distribution
    emit Transfer(address(0), _msgSender(), _totalSupply);

    // Pause the contract after initial setup
    _pause();
    }


//INDICATOR FUNCITONS
    function name() public pure returns (string memory) {
	    return _name;
    }

    function symbol() public pure returns (string memory) {
	    return _symbol;
    }

    function totalSupply() public override view returns (uint256) {
    	return _totalSupply;
    }

    function balanceOf(address account) public override view returns (uint256) {
        if (_isExcluded[account]) return _balances[account];
        return tokenFromReflection(_reflectionBalance[account]);
    }

    function decimals() public pure returns (uint8) {
    return _decimals;
    }

//APPROVAL FUNCTION
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "CAD Token: approve from the zero address");
        require(spender != address(0), "CAD Token: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
//ALLOWANCE
    // Returns the amount of tokens that an owner allowed to a spender.
    // @param owner The address which owns the funds.
    // @param spender The address which will spend the funds.
    // @return The number of tokens still available for the spender.
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    // Increases the allowance granted to `spender` by the caller.
    // This is alternative to `approve` and can be used to mitigate the double spend attack.
    // @param spender The address which will spend the funds.
    // @param addedValue The additional number of tokens to allow.
    // @return A boolean value indicating whether the operation succeeded.
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    // Decreases the allowance granted to `spender` by the caller.
    // @param spender The address which will spend the funds.
    // @param subtractedValue The reduction amount of tokens to allow.
    // @return A boolean value indicating whether the operation succeeded.
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }

//TOKEN REFLECTIONS
    // Returns the amount of reflection from a given token amount.
    // @param tokenAmount The amount of tokens to calculate reflections for.
    // @param deductTransferFee If true, the transfer fee is deducted from the reflection amount.
    // @return The amount of reflection obtained from the given token amount.
    function reflectionFromToken(uint256 tokenAmount, bool deductTransferFee) public view returns (uint256) {    
        require(tokenAmount <= _totalSupply, "Amount must be less than supply");
        if (!deductTransferFee) {    
            return tokenAmount * _getReflectionRate();    
        } else {    
            return tokenAmount - (tokenAmount * _rewardFee / (10**_feeDecimal + 2)) * _getReflectionRate();
        }
    }

    // Converts a reflection amount to its corresponding token amount.
    // @param reflectionAmount The amount of reflections to convert.
    // @return The amount of tokens that corresponds to the given reflection amount.
    function tokenFromReflection(uint256 reflectionAmount) public view returns (uint256) {
        require(reflectionAmount <= _reflectionTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getReflectionRate();    
        return reflectionAmount / currentRate;    
    }

//INCLUDE AND EXCLUDE ACCOUNTS FROM FEE
    function excludeAccount(address account) external onlyOwner {	
	    require(account != rewardWallet, 'CAD: We can not exclude reward wallet.');	
     	require(!_isExcluded[account], "CAD: Account is already excluded");	

	    if (_reflectionBalance[account] > 0) {_balances[account] = tokenFromReflection(_reflectionBalance[account]);
	    }	
	    _isExcluded[account] = true;	
    	_excluded.push(account);	
    }
    
    function includeAccount(address account) external onlyOwner {	
    	require(_isExcluded[account], "CAD: Account is already included");
    	    uint256 length = _excluded.length;
        	for (uint256 i = 0; i < length; i++) {	
                if (_excluded[i] == account) {	
    	        	_excluded[i] = _excluded[length - 1];	
    	         	_balances[account] = 0;	
    	        	_isExcluded[account] = false;	
    	        	_excluded.pop();	
    	        	break;	
    	    }	
        	}
    }

    function isExcluded (address account) public view returns (bool) {	
	    return _isExcluded[account];
    }
 
    function setExcludedFromFee(address account, bool excluded) external onlyOwner {	
    	isExcludedFromFee[account] = excluded;	
    }	    
    
//REFLECTION CALCULATOR
    function _getReflectionRate() private view returns (uint256) {	
    	uint256 reflectionSupply = _reflectionTotal;	
    	uint256 tokenSupply = _totalSupply;	
    	uint256 length = _excluded.length;
    	for (uint256 i = 0; i < length; i++) {	
    	    if (	
    		_reflectionBalance[_excluded[i]] > reflectionSupply ||	
    		_balances[_excluded[i]] > tokenSupply	
    	    ) return _reflectionTotal / _totalSupply;	
    	    reflectionSupply = reflectionSupply - 	
    		_reflectionBalance[_excluded[i]]	
    	    ;	
    	    tokenSupply = tokenSupply - _balances[_excluded[i]];	
    	}	
    	if (reflectionSupply < _reflectionTotal/ _totalSupply)
    	    return _reflectionTotal / _totalSupply;	
    	return reflectionSupply / tokenSupply;	
    }

//FEE CALCULATION     
    // Calculates the tax for a given amount and tax rate.
    // @param amount The amount on which the tax is to be calculated.
    // @param taxRate The tax rate to be applied.
    // @return The calculated tax amount.
    function calculateTax(uint256 amount, uint256 taxRate) private pure returns (uint256) {
        return amount * taxRate / 10**(2 + _feeDecimal); // assuming taxRate is already multiplied by 100 for the percentage representation
    }

    // Collects various fees on a transaction and updates the respective balances.
    // @param account The account from which fees are being collected.
    // @param amount The amount of the transaction.
    // @param rate The current reflection rate.
    // @return The amount remaining after deducting all applicable fees.
    function FeeCollector (address account, uint256 amount, uint256 rate) private returns (uint256) {	
    	uint256 transferAmount = amount;	

        
        //take liquidity fee	
    	if(_liquidityFee != 0) {	
    	    uint256 liquidityFee = calculateTax(amount, _liquidityFee);		
    	    transferAmount = transferAmount - liquidityFee;	
    	    _reflectionBalance[address(this)] = _reflectionBalance[address(this)] + liquidityFee * rate;	
    	    _liquidityFeeTotal = _liquidityFeeTotal + liquidityFee;	
    	    emit Transfer(account,address(this),liquidityFee);	
    	}	
    
    	//tax fee	
    	if(_rewardFee != 0) {	
    	    uint256 rewardFee = calculateTax(amount, _rewardFee);		
    	    transferAmount = transferAmount - rewardFee;	
    	    _reflectionTotal = _reflectionTotal - rewardFee * rate;	
    	    _rewardFeeTotal = _rewardFeeTotal + rewardFee;	
    	}	

    	//take marketing fee	
    	if(_marketingFee != 0) {	
            uint256 marketingFee = calculateTax(amount, _marketingFee);	
            transferAmount = transferAmount - marketingFee;	
            _reflectionBalance[marketingWallet] = _reflectionBalance[marketingWallet] + marketingFee * rate;	
            emit Transfer(account, marketingWallet, marketingFee);	
       }	
        //take developement fee
        if(_developementFee != 0) {	
            uint256 developementFee = calculateTax(amount, _developementFee);	
            transferAmount = transferAmount - developementFee;	
            _reflectionBalance[developmentWallet] = _reflectionBalance[developmentWallet] + developementFee * rate;	
            emit Transfer(account, developmentWallet, developementFee);	
       }	
        //take staking fee
       if(_stakingFee != 0) {	
            uint256 stakingFee = calculateTax(amount, _stakingFee);	
            transferAmount = transferAmount - stakingFee;	
            _reflectionBalance[stakingWallet] = _reflectionBalance[stakingWallet] + stakingFee * rate;	
            emit Transfer(account, stakingWallet, stakingFee);	
       }	
    
    	return transferAmount;	
    }	
    
//TRANSFER FUNCTIONS
    // Public function to transfer tokens.
    // Applies decimal factor, checks for paused state, and protects against reentrancy.
    // @param recipient The address to receive the tokens.
    // @param amount The amount of tokens to be transferred.
    // @return A boolean value indicating whether the operation succeeded.
    function transfer(address recipient, uint256 amount) public override whenNotPaused nonReentrant returns (bool) {
        _transfer(_msgSender(), recipient, amount * (10 ** _decimals)); // Included decimal factor here
        return true;
    }
    
    // Internal function to handle the logic of transferring tokens.
    // Includes various checks and balances along with fee deductions.
    // @param sender The address sending the tokens.
    // @param recipient The address receiving the tokens.
    // @param amount The amount of tokens to be transferred.
    function _transfer(address sender, address recipient, uint256 amount) internal whenNotPaused {
        require(sender != address(0), "CAD Token: transfer from the zero address");
        require(recipient != address(0), "CAD Token: transfer to the zero address");
        require(amount > 0, "CAD Token: transfer amount must be greater than zero");

        // Check for last transaction / Cooldown
        require(block.timestamp - _lastTransferTime[sender] >= MINIMUM_COOLDOWN_TIME, "CAD Token: cooldown period not yet passed");
        // Check if Max Wallet exempt
        if (!_isExemptFromMaxWalletSize[sender] && !_isExemptFromMaxWalletSize[recipient]) {
        }
        // Check if Max Wallet
        if(recipient != uniswapPair && !isExcludedFromFee[recipient]) {
           require(balanceOf(recipient) + amount <= _maxWalletSize, "CAD Token: Exceeds maximum wallet token amount.");
        }
        _lastTransferTime[sender] = block.timestamp;	
    	
    	uint256 transferAmount = amount;	
    	uint256 rate = _getReflectionRate();
        // Check if this is a buy or sell and set the fees accordingly
        uint256 currentRewardFee;
        uint256 currentStakingFee;
        uint256 currentMarketingFee;
        uint256 currentLiquidityFee;

        if(sender == uniswapPair) { // Buy transaction
            currentRewardFee = _rewardFee;
            currentStakingFee = _stakingFee;
            currentMarketingFee = _marketingFee;
            currentLiquidityFee = _liquidityFee;
        } else if(recipient == uniswapPair) { // Sell transaction
            currentRewardFee = sell_rewardFee;
            currentStakingFee = sell_stakingFee;
            currentMarketingFee = sell_marketingFee;
            currentLiquidityFee = sell_liquidityFee;
        } else { // Transfer transaction (not buy/sell)
            currentRewardFee = _rewardFee;
            currentStakingFee = _stakingFee;
            currentMarketingFee = _marketingFee;
            currentLiquidityFee = _liquidityFee;
        }

    	
    	_reflectionBalance[sender] = _reflectionBalance[sender] - amount * rate;	
    	_reflectionBalance[recipient] = _reflectionBalance[recipient] + transferAmount * rate;
    	
    	if(!inSwapAndLiquify) {	
	        swap = true;	
	    	uint256 lpBalance = IERC20(uniswapPair).balanceOf(address(this));	
		if(lpBalance > 100) {	
		    swap = false;	
		}	
	    } 
	    
	    if(swap) {	
		uint256 contractTokenBalance = balanceOf(address(this));	
		bool overMinTokenBalance = contractTokenBalance >= minTokensBeforeSwap;	
		if (overMinTokenBalance && sender != uniswapPair && swapAndLiquifyEnabled) {	
		    swapAndLiquify(contractTokenBalance);	
		    rewardLiquidityProviders();	
		}	
	    }	
		
    	if(!isExcludedFromFee[_msgSender()] && !isExcludedFromFee[recipient]){	
    	    transferAmount = FeeCollector(sender,amount,rate);	
    	}	
    
    	if (_isExcluded[sender]) {	
    	    _balances[sender] = _balances[sender] - amount;	
    	}	
    
    	if (_isExcluded[recipient]) {	
    	    _balances[recipient] = _balances[recipient] + transferAmount;	
    	}
    
	  emit Transfer(sender, recipient, transferAmount);	
    }	
    
    // Public function to transfer tokens on behalf of another address.
    // This is typically used in combination with approve/allowance mechanism.
    // @param sender The address which owns the tokens.
    // @param recipient The address to which the tokens will be transferred.
    // @param amount The amount of tokens to be transferred.
    // @return A boolean value indicating whether the operation succeeded.
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
        _transfer(sender, recipient, amount);
        return true;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

//LIQUIDITY UNISWAP INTERFACE FUNCTIONS   
    function rewardLiquidityProviders() private {	

    	uint256 tokenBalance = balanceOf(rewardWallet);	
    
    	if(tokenBalance > minTokenBeforeReward) {	
    	    uint256 rewardAmount = reflectionFromToken(tokenBalance, false);	
    	    _reflectionBalance[uniswapPair] = _reflectionBalance[uniswapPair] + rewardAmount;	
    	    _reflectionBalance[rewardWallet] = _reflectionBalance[rewardWallet] - rewardAmount;	
    	    emit Transfer(rewardWallet, uniswapPair, tokenBalance);	
    	    IUniswapV2Pair(uniswapPair).sync();	
    	}	
    }
    
    function swapTokensForETHER(uint256 tokenAmount) private {	

    	// generate the UNISWAP pair path of token -> weth	
    	address[] memory path = new address[](2);	
    	path[0] = address(this);	
    	path[1] = uniswapRouter.WETH();	
    
    	_approve(address(this), address(uniswapRouter), tokenAmount);	
    
    	// make the swap	
    	uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(	
    	    tokenAmount,	
    	    0, // accept any amount of ETH	
    	    path,	
    	    address(this),	
    	    block.timestamp	
    	);	
    }	

    function swapETHERForTokens(uint256 EthAmount) private {	
    	address[] memory path = new address[](2);	
    	path[0] = uniswapRouter.WETH();	
    	path[1] = address(this);	
    
    	uniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: EthAmount}(	
    		0,	
    		path,	
    		address(balancerWallet),	
    		block.timestamp	
    	    );	
    }	

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {	

    	// approve token transfer to cover all possible scenarios	
    	_approve(address(this), address(uniswapRouter), tokenAmount);	
    
    	// add the liquidity	
    	uniswapRouter.addLiquidityETH{value: ethAmount}(	
    	    address(this), tokenAmount, 0, 0,	
    	    address(this),	
    	    block.timestamp	
    	);
    }

    function removeLiquidityETH(uint256 lpAmount) private returns(uint256 ETHERamount, uint256 tokenAmount) {    
        IERC20(uniswapPair).approve(address(uniswapRouter), lpAmount);

        // remove the liquidity
        (tokenAmount, ETHERamount) = uniswapRouter.removeLiquidityETH(
            address(this), 
            lpAmount, 
            0,  // amountTokenMin: Minimum amount of ERC20 tokens to receive, set to 0 if unsure
            0,  // amountETHMin: Minimum amount of ETH to receive, set to 0 if unsure
            address(this), 
            block.timestamp);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {	
        // split the contract balance into halves	
        uint256 half = contractTokenBalance / 2;
        uint256 otherHalf = contractTokenBalance - half;

        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH	
        swapTokensForETHER(half);

       // how much ETH did we just swap into?	
        uint256 newBalance = address(this).balance - initialBalance;

        // add liquidity to UNISWAP	
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);

    	//give the swap caller fee	
	    _transfer(address(this), msg.sender, _swapCallerFee);
    }

//FEE CHANGER
    function setSellrewardFee(uint256 fee) external onlyOwner {	
    	sell_rewardFee = fee;	
    }	

    function setSellmarketingFee(uint256 fee) external onlyOwner {	
    	sell_marketingFee = fee;	
    }	

    function setSellStakingFee(uint256 fee) external onlyOwner {	
    	sell_stakingFee = fee;	
    }	

    function setSellLiquidityFee(uint256 fee) external onlyOwner {	
    	sell_liquidityFee = fee;	
    }	

    function setSellDevelopementFee(uint256 fee) external onlyOwner {	
    	sell_developementFee = fee;	
    }	

    function setrewardFee(uint256 fee) external onlyOwner {	
    	_rewardFee = fee;	
    }	

    function setmarketingFee(uint256 fee) external onlyOwner {	
    	_marketingFee = fee;	
    }	

    function setStakingFee(uint256 fee) external onlyOwner {	
    	_stakingFee = fee;	
    }	

    function setLiquidityFee(uint256 fee) external onlyOwner {	
    	_liquidityFee = fee;	
    }	

    function setDevelopementFee(uint256 fee) external onlyOwner {	
    	_developementFee = fee;	
    }	
//MAX WALLET CHANGE
    function setExemptFromMaxWalletSize(address account, bool exempt) external onlyOwner {
        _isExemptFromMaxWalletSize[account] = exempt;
        emit ExemptFromMaxWalletSizeChanged(account, exempt);
    }

    function removeExemptFromMaxWalletSize(address account) external onlyOwner {
        _isExemptFromMaxWalletSize[account] = false;
        emit ExemptFromMaxWalletSizeChanged(account, false);
    }

    function setMaxWalletSize(uint256 maxWalletSize) external onlyOwner {
        require(maxWalletSize > 0, "CAD Token: Max wallet size should be greater than 0");
        _maxWalletSize = maxWalletSize;
        emit MaxWalletSizeChanged(maxWalletSize);
    }
//MINT FUNCTION
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    
    function mint(address to, uint256 amount) public onlyOwner {
        // Convert the amount to wei units, considering the decimals
        uint256 amountWithDecimals = amount;
        // Now call the internal _mint function with the adjusted amount
        _mint(to, amountWithDecimals);
    }
        
//BURN FUNCTION
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "CAD Token: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }
    
    function burn(uint256 amount) public virtual onlyOwner {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual onlyOwner {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "CAD Token: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
//PAUSE FUNCTIONS
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
    
    receive() external payable {}
        
}
