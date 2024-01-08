pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";

import "./IUniswapV2Pair.sol";
import "./IERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract MXSToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    event ExcludeFromRewards(address indexed _address);
    event IncludeInRewards(address indexed _address);
    event ExcludeFromFee(address indexed _address);
    event IncludeInFee(address indexed _address);
    event ExcludeFromPreTrading(address indexed _address);
    event IncludeInPreTrading(address indexed _address);

    event TaxPercentUpdated(uint256 amount);
    event CommunityPercentUpdated(uint256 amount);
    event MaxTxUpdated(uint256 amount);

    event CommunityWalletUpdated(address indexed _address);

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;

    mapping (address => bool) private _isExcludedFromReward;
    
    address[] private _excluded;
  
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 100000000000 * 10 ** 18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _tCommunityTotal;

    string private constant _name = "Marketing Samurai";
    string private constant _symbol = "MXS";
    uint8 private constant _decimals = 18;


    uint256 public _taxFee = 6;
    uint256 private _previousTaxFee = _taxFee;
      
    uint256 public _communityFee = 3;
    uint256 private _previousCommunityFee = _communityFee;

    uint256 public _maxTxAmount = 1000000 * 10 ** 18;

    address public communityAddress = 0x94f6153EbfEB633E9321f9F31Ed19E649239d7DF;
        
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    uint256 private tradingStartTime = 1640966414;
    mapping(address => bool) private canTransferBeforeTradingIsEnabled;
   
    constructor (address uniswapRouter) {
        _rOwned[_msgSender()] = _rTotal;
       
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(uniswapRouter);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[communityAddress] = true;
        
        _isExcludedFromReward[uniswapV2Pair] = true;
        
        canTransferBeforeTradingIsEnabled[owner()] = true;
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) external view override returns (uint256) {
        if (_isExcludedFromReward[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcludedFromReward[account];
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }
      
    function totalCommunityRewards() external view returns (uint256) {
        return _tCommunityTotal;
    }

    function deliver(uint256 tAmount) external {
        address sender = _msgSender();
        require(!_isExcludedFromReward[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }
 
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcludedFromReward[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcludedFromReward[account] = true;
        _excluded.push(account);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        // address must be permitted to transfer before tradingStartTime
        if(tradingStartTime > block.timestamp) {
            require(canTransferBeforeTradingIsEnabled[from], "This account cannot send tokens until trading is enabled");
        }

        if (from != owner() && to != owner()) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }
        
        bool takeFee = true;
        
        // if any account belongs to _isExcludedFromFee account then remove the fee
        // do not take fee if wallet to wallet transfer ( to / from uniswap)
        if ((_isExcludedFromFee[from] || _isExcludedFromFee[to]) || (to != uniswapV2Pair && from != uniswapV2Pair)) {
            takeFee = false;
        }
       
        _tokenTransfer(from,to,amount,takeFee);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee)
            removeAllFee();
       
        if (_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
       
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tCommunity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeCommunity(tCommunity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tCommunity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);          
        _takeCommunity(tCommunity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tCommunity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);  
        _takeCommunity(tCommunity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tCommunity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);       
        _takeCommunity(tCommunity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tCommunity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tCommunity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tCommunity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tCommunity = calculateCommunityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tCommunity);
        return (tTransferAmount, tFee, tCommunity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tCommunity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rCommunity = tCommunity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rCommunity);
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
   
    function _takeCommunity(uint256 tCommunity) private {
        uint256 currentRate =  _getRate();
        uint256 rCommunity = tCommunity.mul(currentRate);
        _rOwned[communityAddress] = _rOwned[communityAddress].add(rCommunity);
        _tCommunityTotal = _tCommunityTotal.add(tCommunity);
        if(_isExcludedFromReward[communityAddress])
            _tOwned[communityAddress] = _tOwned[communityAddress].add(tCommunity);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(100);
    }
      
    function calculateCommunityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_communityFee).div(100);
    }

    function removeAllFee() private {
        if(_taxFee == 0 && _communityFee == 0) return;
       
        _previousTaxFee = _taxFee;
        _previousCommunityFee = _communityFee;

        _taxFee = 0;
        _communityFee = 0;
    }
   
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _communityFee = _previousCommunityFee;
    }

    function isExcludedFromFee(address account) external view returns(bool) {
        return _isExcludedFromFee[account];
    }
   
    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
        emit ExcludeFromFee(account);
    }
   
    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
        emit IncludeInFee(account);
    }
    
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        require(taxFee < 20, "Invalid tax fee");
        _taxFee = taxFee;
        emit TaxPercentUpdated(taxFee);
    }
      
    function setCommunityFeePercent(uint256 communityFee) external onlyOwner() {
        require(communityFee < 20, "Invalid community fee");
        _communityFee = communityFee;
        emit CommunityPercentUpdated(communityFee);
    }

    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
        require(maxTxAmount > 0, "Invalid Max Transaction");
        _maxTxAmount = maxTxAmount;
        emit MaxTxUpdated(maxTxAmount);
    }
    
    function setCommunityWallet(address _address) external onlyOwner {
        communityAddress = _address;
        emit CommunityWalletUpdated(_address);
    }

    function setTradingStartTime(uint256 newStartTime) external onlyOwner {
       require(tradingStartTime > block.timestamp, "Trading has already started");
       require(newStartTime > block.timestamp, "Start time must be in the future");
       tradingStartTime = newStartTime;
    }
    
    function allowPreTrading(address account, bool allowed) external onlyOwner {
        // used for owner and pre sale addresses
        require(canTransferBeforeTradingIsEnabled[account] != allowed, "Pre trading is already the value of 'excluded'");
        canTransferBeforeTradingIsEnabled[account] = allowed;
        if (allowed) {
            emit ExcludeFromPreTrading(account);
        } else {
            emit IncludeInPreTrading(account);
        }
    }
}