// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./IERC20MetadataUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./OwnableUpgradeable.sol";

contract ErrantSpermV2 is OwnableUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    using SafeMathUpgradeable for uint256;

    string private _name;
    string private _symbol;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    mapping (address => mapping (address => uint256)) private _allowances;

    address[] private _excluded;
    address public _marketingWallet;
    address public _devWallet;

    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;

    uint256 public  _taxFee;
    uint256 public  _marketingFee;
    uint256 public  _developmentFee;

    uint256 public  _maxTxAmount;

    event PaidChildSupport(address indexed from, address indexed to, uint256 tokens, uint64 date);

    function initialize() public initializer {
      __Ownable_init();
      _name = "ErrantSperm";
      _symbol = "SPERM";

      uint256 MAX = ~uint256(0);
      _tTotal = 1000000000 * 10**9;
      _rTotal = (MAX - (MAX % _tTotal));

      _taxFee         = 200; // 2.0% of every transaction will be redistributed to holders
      _marketingFee   =   0; //   0% of every transaction will be sent to marketing wallet
      _developmentFee = 100; // 1.0% of every transaction will be sent to development address
      _maxTxAmount = _tTotal / 2;

      _marketingWallet = 0xcA7cd9519f7c047B447DFf4142aF2fe11B09dC13;
      _devWallet     = 0xcA7cd9519f7c047B447DFf4142aF2fe11B09dC13;

      _rOwned[_msgSender()] = _rTotal;

      // exclude system contracts
      _isExcludedFromFee[owner()]        = true;
      _isExcludedFromFee[address(this)]  = true;
      _isExcludedFromFee[_marketingWallet] = true;
      _isExcludedFromFee[_devWallet]     = true;

      emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        (, uint256 tFee, uint256 tMarketing, uint256 tDevelopment) = _getTValues(tAmount);
        uint256 currentRate = _getRate();

        if (!deductTransferFee) {
            (uint256 rAmount,,) = _getRValues(tAmount, tFee, tMarketing, tDevelopment, currentRate);
            return rAmount;

        } else {
            (, uint256 rTransferAmount,) = _getRValues(tAmount, tFee, tMarketing, tDevelopment, currentRate);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");

        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");

        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already included");

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

    function setExcludedFromFee(address account, bool e) external onlyOwner {
        _isExcludedFromFee[account] = e;
    }

    function setTaxFeePercent(uint256 taxFee) external onlyOwner {
        _taxFee = taxFee;
    }

    function setMarketingFeePercent(uint256 marketingFee) external onlyOwner {
        _marketingFee = marketingFee;
    }

    function setDevelopmentFeePercent(uint256 developmentFee) external onlyOwner {
        _developmentFee = developmentFee;
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(100);
    }

    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal    = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee         = tAmount.mul(_taxFee).div(10000);
        uint256 tMarketing     = tAmount.mul(_marketingFee).div(10000);
        uint256 tDevelopment = tAmount.mul(_developmentFee).div(10000);
        uint256 tTransferAmount = tAmount.sub(tFee);
        tTransferAmount = tTransferAmount.sub(tMarketing);
        tTransferAmount = tTransferAmount.sub(tDevelopment);
        return (tTransferAmount, tFee, tMarketing, tDevelopment);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tMarketing, uint256 tDevelopment, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount      = tAmount.mul(currentRate);
        uint256 rFee         = tFee.mul(currentRate);
        uint256 rCharity     = tMarketing.mul(currentRate);
        uint256 rDevelopment = tDevelopment.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        rTransferAmount = rTransferAmount.sub(rCharity);
        rTransferAmount = rTransferAmount.sub(rDevelopment);
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

    function takeTransactionFee(address to, uint256 tAmount, uint256 currentRate) private {
        if (tAmount <= 0) { return; }

        uint256 rAmount = tAmount.mul(currentRate);
        if (rAmount != 0) {
            _rOwned[to] = _rOwned[to].add(rAmount);
        }
        if (_isExcluded[to]) {
            if (tAmount != 0) {
                _tOwned[to] = _tOwned[to].add(tAmount);
            }
        }
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _transfer (
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != owner() && to != owner()) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        bool takeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        _tokenTransfer(from, to, amount, takeFee);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        uint256 previousTaxFee         = _taxFee;
        uint256 previousCharityFee     = _marketingFee;
        uint256 previousDevelopmentFee = _developmentFee;

        if (!takeFee) {
            _taxFee         = 0;
            _marketingFee   = 0;
            _developmentFee = 0;
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

        if (!takeFee) {
            _taxFee         = previousTaxFee;
            _marketingFee     = previousCharityFee;
            _developmentFee = previousDevelopmentFee;
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tMarketing, uint256 tDevelopment) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tMarketing, tDevelopment, currentRate);

        _rOwned[sender]    = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        takeTransactionFee(_marketingWallet, tMarketing, currentRate);
        takeTransactionFee(_devWallet, tDevelopment, currentRate);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
        if (tMarketing != 0) {
            emit Transfer(sender, _marketingWallet, tMarketing);
        }
        if (tDevelopment != 0) {
            emit Transfer(sender, _devWallet, tDevelopment);
        }
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tMarketing, uint256 tDevelopment) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tMarketing, tDevelopment, currentRate);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        takeTransactionFee(_marketingWallet, tMarketing, currentRate);
        takeTransactionFee(_devWallet, tDevelopment, currentRate);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
        if (tMarketing != 0) {
            emit Transfer(sender, _marketingWallet, tMarketing);
        }
        if (tDevelopment != 0) {
            emit Transfer(sender, _devWallet, tDevelopment);
        }
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tMarketing, uint256 tDevelopment) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tMarketing, tDevelopment, currentRate);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        takeTransactionFee(_marketingWallet, tMarketing, currentRate);
        takeTransactionFee(_devWallet, tDevelopment, currentRate);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
        if (tMarketing != 0) {
            emit Transfer(sender, _marketingWallet, tMarketing);
        }
        if (tDevelopment != 0) {
            emit Transfer(sender, _devWallet, tDevelopment);
        }
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tMarketing, uint256 tDevelopment) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tMarketing, tDevelopment, currentRate);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        takeTransactionFee(_marketingWallet, tMarketing, currentRate);
        takeTransactionFee(_devWallet, tDevelopment, currentRate);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
        if (tMarketing != 0) {
            emit Transfer(sender, _marketingWallet, tMarketing);
        }
        if (tDevelopment != 0) {
            emit Transfer(sender, _devWallet, tDevelopment);
        }
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function payChildSupport(address _to, uint256 _amount, uint64 _date) public returns(bool) {
        if (transfer(_to, _amount)) {
            emit PaidChildSupport(msg.sender, _to, _amount, _date);
            return true;
        } else {
            return false;
        }
    }

    function setDevelopmentWallet(address newDevelopmentWallet) external onlyOwner {
        _devWallet = newDevelopmentWallet;
    }

    function setMarketingWallet(address newMarketingWallet) external onlyOwner {
        _marketingWallet = newMarketingWallet;
    }
}
