/*

Website: http://bullbtc.vip
Twitter: https://x.com/BULLBTCERC
Telegram: https://t.me/bullbtcportal

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(address(msg.sender));
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor ()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

interface IDexFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDexRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract BTC is Context, IERC20, Ownable {

    using SafeMath for uint256;
    
    address constant dead = 0x000000000000000000000000000000000000dEaD;
    
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isWalletLimitExempt;

    uint256 private constant MAX = ~uint256(0);
    
    uint256 private _tFeeTotal;

    string public constant _name ="BULLBTC";
    string public constant _symbol = "BTC";
    uint8 private constant _decimals = 18;

    uint256 public _tTotal = 1_000_000_000 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    uint256 sDenominator = 1000;

    uint256 public numTokensSellToAddToLiquidity = _tTotal.mul(5).div(sDenominator);

    uint256 public _maxTxAmount = 4000000 * 10**_decimals;
    uint256 public _walletMax = 4000000 * 10**_decimals; 

    bool public EnableTransactionLimit = true;
    bool public checkWalletLimit = true;

    uint256 private _taxFee = 0;                           
    uint256 private _previousTaxFee = _taxFee;

    uint256 private _MarketingFee = 0;
    uint256 private _previousMarketingFee = _MarketingFee;

    uint256 private _burnRate;

    IDexRouter public pcsV2Router;
    address public pcsV2Pair;

    address private MarketingWallet;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;    
    bool public swapProtection = true;
    bool public swingTradeProtected = true;

    bool tradingEnable;
    bool LimitDynamic = false;
    uint256 public launchedTime;
    uint256 public nextLimitIncrease;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    struct BuyFee{
        uint256 setTaxFee;
        uint256 setMarketingFee;
    }

    struct SellFee{
        uint256 setTaxFee;
        uint256 setMarketingFee;
    }

    BuyFee public buyFee;
    SellFee public sellFee;

    constructor ()  {       

        MarketingWallet = _msgSender();
        
        _rOwned[_msgSender()] = _rTotal;

        buyFee.setTaxFee = 10;
        buyFee.setMarketingFee = 20;

        sellFee.setTaxFee = 10;
        sellFee.setMarketingFee = 20;

        _burnRate = 50;
                
        IDexRouter _pcsV2Router = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
          
        pcsV2Pair = IDexFactory(_pcsV2Router.factory())
            .createPair(address(this), _pcsV2Router.WETH());

        pcsV2Router = _pcsV2Router;
        
        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(dead)] = true;

        isWalletLimitExempt[_msgSender()] = true;
        isWalletLimitExempt[address(dead)] = true;
        isWalletLimitExempt[pcsV2Pair] = true;
        isWalletLimitExempt[address(this)] = true;

        isTxLimitExempt[_msgSender()] = true;
        isTxLimitExempt[address(this)] = true;

        excludeFromReward(address(dead));

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amt must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amt must be less than tot refl");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded from reward");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
    
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tMarketing) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tMarketing, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tMarketing);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tMarketing = calculateMarketingFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tMarketing);
        return (tTransferAmount, tFee, tMarketing);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tMarketing, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tMarketing.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function _takeMarketing(address sender,uint256 tMarketing) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tMarketing.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tMarketing);
        if(tMarketing > 0) emit Transfer(sender, address(this), tMarketing);
    }
    
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(sDenominator);
    }

    function calculateMarketingFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_MarketingFee).div(sDenominator);
    }
  
    function removeAllFee() private {
        uint subtotal = _taxFee.add(_MarketingFee);
        if(subtotal == 0) return; 
        
        _previousTaxFee = _taxFee;
        _previousMarketingFee = _MarketingFee;

        _taxFee = 0;
        _MarketingFee = 0;
    }
    
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _MarketingFee = _previousMarketingFee;
    }

    function setBuy() private {
        _taxFee = buyFee.setTaxFee;
        _MarketingFee = buyFee.setMarketingFee;
    }
    
    function setSell() private {
        _taxFee = sellFee.setTaxFee;
        _MarketingFee = sellFee.setMarketingFee;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from zero address");
        require(spender != address(0), "ERC20: approve to zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0));
        require(to != address(0));
        require(amount > 0);

        if(!tradingEnable) {
            require(_isExcludedFromFee[from] || _isExcludedFromFee[to], "Trading Paused"); 
        }

        if(block.timestamp > nextLimitIncrease && LimitDynamic) {
            uint newLimitTx = _maxTxAmount.mul(100).div(sDenominator); 
            uint newLimitWallet = _walletMax.mul(100).div(sDenominator); 
            _maxTxAmount = _maxTxAmount.add(newLimitTx);
            _walletMax = _walletMax.add(newLimitWallet);
            nextLimitIncrease = block.timestamp + 12 hours;
        }

        if(!isTxLimitExempt[from] && !isTxLimitExempt[to] && EnableTransactionLimit) {
            require(amount <= _maxTxAmount, "Exceeds max Tx");
        }

        if(checkWalletLimit && !isWalletLimitExempt[to]) {
            require(balanceOf(to).add(amount) <= _walletMax,"Exceeds Wallet Limit.");
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            !inSwapAndLiquify &&
            to == pcsV2Pair &&
            swapAndLiquifyEnabled &&
            overMinTokenBalance
        ) {            
            swapAndLiquify(contractTokenBalance);
        }
        
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }

        _tokenTransfer(from,to,amount,takeFee);

    }

    function swapAndLiquify(uint contractSwapTokens) private lockTheSwap {

        if(swapProtection) contractSwapTokens = numTokensSellToAddToLiquidity;

        uint tokensForBurn = contractSwapTokens.mul(_burnRate).div(sDenominator);
        contractSwapTokens = contractSwapTokens.sub(tokensForBurn);

        if(tokensForBurn > 0) {
            _tokenTransferNoFee(address(this), address(dead) ,tokensForBurn);
        }
        if(contractSwapTokens > 0) {
            swapTokensForETH(contractSwapTokens, MarketingWallet);
        }
    }
        
    function swapTokensForETH(uint256 tokenAmount, address recipient) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pcsV2Router.WETH();

        _approve(address(this), address(pcsV2Router), tokenAmount);

        // make the swap
        pcsV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(recipient),
            block.timestamp
        );
    }
    
    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        
            removeAllFee();

            if (takeFee){

                if (sender == pcsV2Pair) {
                    setBuy();
                }
                if (recipient == pcsV2Pair) {
                    if(block.timestamp <= launchedTime + 96 hours) {
                        setDynamicTax();
                    } else {
                        setSell();
                    }
                }

            } 

        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tMarketing) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeMarketing(sender,tMarketing);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tMarketing) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeMarketing(sender,tMarketing);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tMarketing) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeMarketing(sender,tMarketing);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tMarketing) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeMarketing(sender,tMarketing);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _tokenTransferNoFee(address sender, address recipient, uint256 amount) private {
        uint256 currentRate =  _getRate();  
        uint256 rAmount = amount.mul(currentRate);   

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rAmount); 
        
        if (_isExcluded[sender]) {
            _tOwned[sender] = _tOwned[sender].sub(amount);
        } 
        if (_isExcluded[recipient]) {
            _tOwned[recipient] = _tOwned[recipient].add(amount);
        } 
        emit Transfer(sender, recipient, amount);
    }

    function setDynamicTax() private {
        uint timePassed = block.timestamp - launchedTime;
        if(timePassed < 24 hours) {
            _taxFee = 20;  //2
            _MarketingFee = 480; //48
        }
        else if (timePassed < 48 hours) {
            _taxFee = 20;
            _MarketingFee = 230;
        }
        else if (timePassed < 72 hours) {
            _taxFee = 20;
            _MarketingFee = 80;
        }
        else if (timePassed <= 96 hours) {
            _taxFee = 10;
            _MarketingFee = 20;
        }
    }
    
    function excludeFromFee(address account) external onlyOwner() {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) external onlyOwner() {
        _isExcludedFromFee[account] = false;
    }

    function setMFeeWallet(address payable newFeeWallet) external onlyOwner() {
        MarketingWallet = newFeeWallet;
    }

    function setSwapSetting(bool _swapEnable, bool _protected, uint256 _swapthreshold) external {
        require(msg.sender == MarketingWallet);
        swapAndLiquifyEnabled = _swapEnable;
        swapProtection = _protected;
        numTokensSellToAddToLiquidity = _swapthreshold;
    }

    function setBurnRate(uint _Brate) external {
        require(msg.sender == MarketingWallet);
        _burnRate = _Brate;
    }

    function sellProtection(bool _status) external {
        require(msg.sender == MarketingWallet);
        swingTradeProtected = _status;
    }
    
    function dynamicLimit(bool _status) external {
        require(msg.sender == MarketingWallet);
        LimitDynamic = _status;
    }

    function recoverFunds() external {
        require(msg.sender == MarketingWallet);
        (bool os,) = payable(msg.sender).call{value: address(this).balance}("");
        require(os);
    }

    function clearStuckTokens(address tokenAddress, address _recipient, uint256 tokenAmount) external {
        require(msg.sender == MarketingWallet);
        if(tokenAddress == address(this)) {
            _tokenTransferNoFee(address(this), _recipient ,tokenAmount);
        }         
        else {
            (bool os,) = address(tokenAddress).call(abi.encodeWithSignature("transfer(address,uint256)",_recipient,tokenAmount));
            if(!os) revert('Failed');
        }
    }

    function setMaxWalletLimit(uint256 newLimit) external onlyOwner() {
        _walletMax = newLimit;
    }

    function setTxLimit(uint256 newLimit) external onlyOwner() {
        _maxTxAmount = newLimit;
    }

    function ExcludeWalletLimit(address _adr,bool _status) external onlyOwner {
        isWalletLimitExempt[_adr] = _status;
    }

    function ExcludeTxLimit(address _adr,bool _status) external onlyOwner {
        isTxLimitExempt[_adr] = _status;
    }

    function setLimits(bool _walletlimit, bool txlimit) external onlyOwner {
        EnableTransactionLimit = txlimit;
        checkWalletLimit = _walletlimit;
    }

    function setBuyFee(
        uint _newReflection,
        uint _newMarketing
    ) external onlyOwner {
        buyFee.setTaxFee = _newReflection;
        buyFee.setMarketingFee = _newMarketing;
    }

    function setSellFee(
        uint _newReflection,
        uint _newMarketing
    ) external onlyOwner {
        sellFee.setTaxFee = _newReflection;
        sellFee.setMarketingFee = _newMarketing;
    }

    function openTrade() external onlyOwner {
        require(!tradingEnable,"Already Enabled!");
        tradingEnable = true;
        launchedTime = block.timestamp;
        nextLimitIncrease = block.timestamp + 12 hours;
        LimitDynamic = true;
    }

}