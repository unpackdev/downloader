/*

🌎 Website: https://dorkplay.online
✅ Telegram: Portal: https://t.me/dorkplayportal
✔️ Twitter: https://twitter.com/DorkPlayETH

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address _account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any _account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IDexSwapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDexSwapPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IDexSwapRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
			uint amountOutMin,
			address[] calldata path,
			address to,
			uint deadline
		) external payable;
}

interface IDividendDistributor {
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
}

contract DORK is Context, IERC20, Ownable {

    using SafeMath for uint256;

    uint256 private buyLiquidityFee = 0;
    uint256 private buyMarketingFee = 15;
    uint256 private buyRewardsFee = 0;

    uint256 private sellLiquidityFee = 0;
    uint256 private sellMarketingFee = 35;
    uint256 private sellRewardsFee = 0;

    uint256 public buyTax = 15;
    uint256 public sellTax = 35;

    uint256 private feeDenominator = 100;

    address private liquidityWallet;
    address private _marketingWallet = address(0x2bc846E6FCe00f096E2C9F66879f74C319f77b75);

    address private constant deadWallet = 0x000000000000000000000000000000000000dEaD;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) public isExcludedFromFee;
    mapping (address => bool) public isMarketPair;
    mapping (address => bool) public isWalletLimitExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isDividendExempt;

    string private _name = "Dorkplay";
    string private _symbol = "DORK";
    uint8 private _decimals = 18; 
    
    uint256 private _totalSupply = 4_000_000 * 10**_decimals;

    uint256 public _maxTxAmount =  _totalSupply.mul(4).div(100);     // 4%
    uint256 public _walletMax = _totalSupply.mul(4).div(100);        // 4%

    uint256 public swapThreshold = _totalSupply.mul(1).div(100);

    bool public swapEnabled = true;
    bool public swapbylimit = true;
    bool public EnableTxLimit = true;
    bool public checkWalletLimit = true;
  
    IDividendDistributor public distributor;
 
    address public pair;
    IDexSwapRouter public router;

    bool public tradingEnable; 
    uint256 public launchedAt;
    uint256 private launchCooldown;
    bool public normalizeTrade;

    bool inSwap = false;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {

        liquidityWallet = msg.sender;

        router = IDexSwapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 

        pair = IDexSwapFactory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );

        _allowances[address(this)][address(router)] = ~uint256(0);

        isDividendExempt[msg.sender] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[deadWallet] = true;
        
        isWalletLimitExempt[msg.sender] = true;
        isWalletLimitExempt[pair] = true;
        isWalletLimitExempt[address(this)] = true;
        isWalletLimitExempt[deadWallet] = true;

        isExcludedFromFee[msg.sender] = true;
        isExcludedFromFee[address(this)] = true;

        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[deadWallet] = true;
        isTxLimitExempt[address(this)] = true;

        isMarketPair[pair] = true;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0x0), msg.sender, _totalSupply);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
       return _balances[account];     
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

     //to recieve ETH from Router when swaping
    receive() external payable {}

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: Exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {

        require(sender != address(0));
        require(recipient != address(0));
        require(amount > 0);
    
        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }
        else {

            if(!tradingEnable) {
                require(isExcludedFromFee[sender] || isExcludedFromFee[recipient], "Trading Paused"); 
            }

            if (tradingEnable && block.timestamp > launchedAt + launchCooldown && !normalizeTrade) {
                normalizeTax();
                normalizeTrade = true;
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= swapThreshold;

            if (
                overMinimumTokenBalance && 
                !inSwap && 
                !isMarketPair[sender] && 
                swapEnabled &&
                !isExcludedFromFee[sender] &&
                !isExcludedFromFee[recipient]
                ) {
                swapBack(contractTokenBalance);
            }

            if(!isTxLimitExempt[sender] && !isTxLimitExempt[recipient] && EnableTxLimit) {
                require(amount <= _maxTxAmount, "Exceeds maxTxAmount");
            } 
            
            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

            uint256 finalAmount = shouldNotTakeFee(sender,recipient) ? amount : takeFee(sender, recipient, amount);

            if(checkWalletLimit && !isWalletLimitExempt[recipient]) {
                require(balanceOf(recipient).add(finalAmount) <= _walletMax,"Exceeds Wallet");
            }

            _balances[recipient] = _balances[recipient].add(finalAmount);

            if(!isDividendExempt[sender]){ try distributor.setShare(sender, balanceOf(sender)) {} catch {} }
            if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, balanceOf(recipient)) {} catch {} }

            emit Transfer(sender, recipient, finalAmount);
            return true;

        }

    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function shouldNotTakeFee(address sender, address recipient) internal view returns (bool) {
        if(isExcludedFromFee[sender] || isExcludedFromFee[recipient]) {
            return true;
        }
        else if (isMarketPair[sender] || isMarketPair[recipient]) {
            return false;
        }
        else {
            return false;
        }
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        
        uint feeAmount;

        unchecked {

            if(isMarketPair[sender]) { 
                feeAmount = amount.mul(buyTax).div(feeDenominator);
            } 
            else if(isMarketPair[recipient]) { 
                feeAmount = amount.mul(sellTax).div(feeDenominator);
            }

            if(feeAmount > 0) {
                _balances[address(this)] = _balances[address(this)].add(feeAmount);
                emit Transfer(sender, address(this), feeAmount);
            }

            return amount.sub(feeAmount);
        }
        
    }


    function swapBack(uint contractBalance) internal swapping {

        if(swapbylimit) contractBalance = swapThreshold;

        uint256 totalShares = buyTax.add(sellTax);
        if(totalShares == 0) return;   

        uint256 _liquidityShare = buyLiquidityFee.add(sellLiquidityFee);
        uint256 _MarketingShare = buyMarketingFee.add(sellMarketingFee);
        // uint256 _RewardShare = buyRewardsFee.add(sellRewardsFee);

        uint256 tokensForLP = contractBalance.mul(_liquidityShare).div(totalShares).div(2);
        uint256 tokensForSwap = contractBalance.sub(tokensForLP);

        uint256 initialBalance = address(this).balance;
        swapTokensForEth(tokensForSwap);
        uint256 amountReceived = address(this).balance.sub(initialBalance);

        uint256 totalETHFee = totalShares.sub(_liquidityShare.div(2));
        
        uint256 amountETHLiquidity = amountReceived.mul(_liquidityShare).div(totalETHFee).div(2);
        uint256 amountETHMarketing = amountReceived.mul(_MarketingShare).div(totalETHFee);
        uint256 amountETHReward = amountReceived.sub(amountETHMarketing).sub(amountETHLiquidity);

        if(amountETHMarketing > 0)
            payable(_marketingWallet).transfer(amountETHMarketing);

        if(amountETHReward > 0) 
            try distributor.deposit { value: amountETHReward } () {} catch {}  

        if(amountETHLiquidity > 0 && tokensForLP > 0)
            addLiquidity(tokensForLP, amountETHLiquidity);

    }

    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && !isMarketPair[holder]);
        isDividendExempt[holder] = exempt;

        if (exempt) {
            distributor.setShare(holder, 0);
        } else {
            distributor.setShare(holder, balanceOf(holder));
        }
    }

    function rescueFunds() external { 
        require(msg.sender == liquidityWallet,"Unauthorized!");
        (bool os,) = payable(msg.sender).call{value: address(this).balance}("");
        require(os,"Transaction Failed!!");
    }

    function rescueTokens(address _token,address recipient,uint _amount) external {
        require(msg.sender == liquidityWallet,"Unauthorized!");
        (bool success, ) = address(_token).call(abi.encodeWithSignature('transfer(address,uint256)',  recipient, _amount));
        require(success, 'Token payment failed');
    }

    function setBuyFee(uint _lp, uint _marketing, uint _reward) external onlyOwner {    
        buyLiquidityFee = _lp;
        buyMarketingFee = _marketing;
        buyRewardsFee = _reward;
        buyTax = buyLiquidityFee.add(buyMarketingFee).add(buyRewardsFee);
    }

    function setSellFee(uint _lp, uint _marketing, uint _reward) external onlyOwner {     
        sellLiquidityFee = _lp;
        sellMarketingFee = _marketing;
        sellRewardsFee = _reward;
        sellTax = sellLiquidityFee.add(sellMarketingFee).add(sellRewardsFee);
    }

    function normalizeTax() internal {
        buyLiquidityFee = 1;
        buyMarketingFee = 1;
        buyRewardsFee = 1;
        buyTax = 3;
        sellLiquidityFee = 1;
        sellMarketingFee = 2;
        sellRewardsFee = 2;
        sellTax = 5;
    }

    function setRewardDividend(address _dividend) external onlyOwner {
        distributor = IDividendDistributor(_dividend);
    }

    function setSwapBackSettings(uint _threshold, bool _enabled, bool _limited)
        external
    {
        require(msg.sender == liquidityWallet,"Unauthorized!");
        swapEnabled = _enabled;
        swapbylimit = _limited;
        swapThreshold = _threshold;
    }

    function enableTrading() external onlyOwner {
        require(!tradingEnable, "Trade Enabled!");

        tradingEnable = true;
        launchedAt = block.timestamp;
        launchCooldown = 3 minutes; 
    }

    function removeLimits() external onlyOwner {
        EnableTxLimit = false;
        checkWalletLimit =  false;
    }

    function enableTxLimit(bool _status) external onlyOwner {
        EnableTxLimit = _status;
    }

    function enableWalletLimit(bool _status) external onlyOwner {
        checkWalletLimit = _status;
    }

    function excludeFromFee(address _adr,bool _status) external onlyOwner {
        isExcludedFromFee[_adr] = _status;
    }

    function excludeWalletLimit(address _adr,bool _status) external onlyOwner {
        isWalletLimitExempt[_adr] = _status;
    }

    function excludeTxLimit(address _adr,bool _status) external onlyOwner {
        isTxLimitExempt[_adr] = _status;
    }

    function setMaxWalletLimit(uint256 newLimit) external onlyOwner() {
        _walletMax = newLimit;
    }

    function setTxLimit(uint256 newLimit) external onlyOwner() {
        _maxTxAmount = newLimit;
    }

    function setLiquidityWallets(address _newWallet) external onlyOwner {
        liquidityWallet = _newWallet;
    }

    function setMarketingWallets(address _newWallet) external onlyOwner {
        _marketingWallet = _newWallet;
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);
        // add the liquidity
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityWallet,
            block.timestamp
        );

    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

    }

}