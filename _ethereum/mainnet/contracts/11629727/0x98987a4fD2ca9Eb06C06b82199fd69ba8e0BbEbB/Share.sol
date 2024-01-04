// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./Operator.sol";

contract Share is Context, IERC20, Operator {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcluded;
    address[] private _excluded;
    mapping(address => bool) private _feeless;
    mapping(address => bool) private _pools;

    uint256 private constant MAX = uint256(- 1);
    uint256 private constant _tTotal = 1000001 * 10 ** 18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _feeDivisor = 80; // 1.25%

    struct Values {
        uint256 amount;
        uint256 transferAmount;
        uint256 fee;
    }

    string private _name = 'REFLECT.CASH SHARE';
    string private _symbol = 'RFS';
    uint8 private _decimals = 18;

    constructor () public {
        _rOwned[address(this)] = _rTotal;
        excludeAccount(address(this));
        _feeless[address(this)] = true;

        _transfer(address(this), _msgSender(), 1e18);
    }

    modifier onlyPool() {
        require(_pools[_msgSender()], "Caller is not pool");
        _;
    }

    /* =================== Only Pool =================== */

    function withdraw(address recipient, uint256 amount) external onlyPool {
        _transfer(address(this), recipient, amount);
    }

    /* =================== Only Owner =================== */

    function setPool(address _pool, bool value) external onlyOperator {
        _pools[_pool] = value;
    }

    function setFeeless(address account, bool value) external onlyOwner {
        _feeless[account] = value;
    }

    function setFeeDivisor(uint256 feeDivisor) external onlyOwner {
        require(feeDivisor >= 50, "Invalid fee"); // Max 2%
        _feeDivisor = feeDivisor;
    }

    function excludeAccount(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) public onlyOwner {
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

    /* =================== Public =================== */

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

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflect(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (Values memory r,) = _getValues(tAmount, !_feeless[sender]);
        _rOwned[sender] = _rOwned[sender].sub(r.amount);
        _rTotal = _rTotal.sub(r.amount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        (Values memory r,) = _getValues(tAmount, true);
        if (!deductTransferFee) {
            return r.amount;
        } else {
            return r.transferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    /* =================== Private =================== */

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        bool hasFee = !_feeless[sender] && !_feeless[recipient];
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount, hasFee);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount, hasFee);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount, hasFee);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount, hasFee);
        } else {
            _transferStandard(sender, recipient, amount, hasFee);
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount, bool hasFee) private {
        (Values memory r, Values memory t) = _getValues(tAmount, hasFee);
        _rOwned[sender] = _rOwned[sender].sub(r.amount);
        _rOwned[recipient] = _rOwned[recipient].add(r.transferAmount);
        _reflectFee(r.fee, t.fee);
        emit Transfer(sender, recipient, t.transferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount, bool hasFee) private {
        (Values memory r, Values memory t) = _getValues(tAmount, hasFee);
        _rOwned[sender] = _rOwned[sender].sub(r.amount);
        _tOwned[recipient] = _tOwned[recipient].add(t.transferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(r.transferAmount);
        _reflectFee(r.fee, t.fee);
        emit Transfer(sender, recipient, t.transferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount, bool hasFee) private {
        (Values memory r, Values memory t) = _getValues(tAmount, hasFee);
        _tOwned[sender] = _tOwned[sender].sub(t.amount);
        _rOwned[sender] = _rOwned[sender].sub(r.amount);
        _rOwned[recipient] = _rOwned[recipient].add(r.transferAmount);
        _reflectFee(r.fee, t.fee);
        emit Transfer(sender, recipient, t.transferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount, bool hasFee) private {
        (Values memory r, Values memory t) = _getValues(tAmount, hasFee);
        _tOwned[sender] = _tOwned[sender].sub(t.amount);
        _rOwned[sender] = _rOwned[sender].sub(r.amount);
        _tOwned[recipient] = _tOwned[recipient].add(t.transferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(r.transferAmount);
        _reflectFee(r.fee, t.fee);
        emit Transfer(sender, recipient, t.transferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount, bool hasFee) private view returns (Values memory r, Values memory t) {
        t = _getTValues(tAmount, hasFee);
        r = _getRValues(t, _getRate());
    }

    function _getTValues(uint256 tAmount, bool hasFee) private view returns (Values memory t) {
        t.amount = tAmount;
        if (hasFee) {
            t.fee = tAmount.div(_feeDivisor);
        }
        t.transferAmount = tAmount.sub(t.fee);
    }

    function _getRValues(Values memory t, uint256 currentRate) private pure returns (Values memory r) {
        r.amount = t.amount.mul(currentRate);
        r.fee = t.fee.mul(currentRate);
        r.transferAmount = r.amount.sub(r.fee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
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
}