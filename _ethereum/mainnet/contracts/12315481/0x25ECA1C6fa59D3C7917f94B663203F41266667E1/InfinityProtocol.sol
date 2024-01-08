pragma solidity 0.7.4;

import "./Context.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./IInfinityProtocol.sol";

contract InfinityProtocol is IInfinityProtocol, Context, Ownable {

    using SafeMath for uint;
    using Address for address;

    mapping (address => uint) private _rOwned;
    mapping (address => uint) private _tOwned;
    mapping (address => mapping (address => uint)) private _allowances;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    address public feeReceiver;
    address public router;
    uint public maxCycles;

    string  private constant _NAME = "infinityprotocol.io";
    string  private constant _SYMBOL = "INFINITY";
    uint8   private constant _DECIMALS = 8;

    uint private constant _MAX = ~uint(0);
    uint private constant _DECIMALFACTOR = 10 ** uint(_DECIMALS);
    uint private constant _GRANULARITY = 100;

    uint private _tTotal = 100000000 * _DECIMALFACTOR;
    uint private _rTotal = (_MAX - (_MAX % _tTotal));

    uint private _tFeeTotal;
    uint private _tBurnTotal;
    uint private _infinityCycle;

    uint private _tTradeCycle;
    uint private _tBurnCycle;

    uint private _BURN_FEE;
    uint private _FOT_FEE;
    bool private _feeSet;

    uint private constant _MAX_TX_SIZE = 100000000 * _DECIMALFACTOR;

    constructor (address _router) public {
        _rOwned[_msgSender()] = _rTotal;
        router = _router;
        setMaxCycles(500);
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _NAME;
    }

    function symbol() public pure returns (string memory) {
        return _SYMBOL;
    }

    function decimals() public pure returns (uint8) {
        return _DECIMALS;
    }

    function totalSupply() public view override returns (uint) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint) {
        return _tFeeTotal;
    }

    function totalBurn() public view returns (uint) {
        return _tBurnTotal;
    }

    function setFeeReceiver(address receiver) external onlyOwner() returns (bool) {
        require(receiver != address(0), "Zero address not allowed");
        feeReceiver = receiver;
        return true;
    }

    function totalBurnWithFees() public view returns (uint) {
        return _tBurnTotal.add(_tFeeTotal);
    }

    function reflectionFromToken(uint transferAmount, bool deductTransferFee) public view returns(uint) {
        require(transferAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint rAmount,,,,,) = _getValues(transferAmount);
            return rAmount;
        } else {
            (,uint rTransferAmount,,,,) = _getValues(transferAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint rAmount) public view returns(uint) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeAccount(address account) external onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        require(account != router, 'Not allowed to exclude router');
        require(account != feeReceiver, "Can not exclude fee receiver");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already included");
        for (uint i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _approve(address owner, address spender, uint amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        // @dev once all cycles are completed, burn fee will be set to 0 and the protocol
        // reaches its final phase, in which no further supply elasticity will take place
        // and fees will stay at 0

        if (sender != owner() && recipient != owner())
            require(amount <= _MAX_TX_SIZE, "Transfer amount exceeds the maxTxAmount.");

        // @dev 50% fee is burn fee, 50% is fot
        if (_BURN_FEE >= 250) {

            _tTradeCycle = _tTradeCycle.add(amount);


        // @dev adjust current burnFee/fotFee depending on the traded tokens
            if (_tTradeCycle >= (0 * _DECIMALFACTOR) && _tTradeCycle <= (1000000 * _DECIMALFACTOR)) {
                _setFees(500);
            } else if (_tTradeCycle > (1000000 * _DECIMALFACTOR) && _tTradeCycle <= (2000000 * _DECIMALFACTOR)) {
                _setFees(550);
            }   else if (_tTradeCycle > (2000000 * _DECIMALFACTOR) && _tTradeCycle <= (3000000 * _DECIMALFACTOR)) {
                _setFees(600);
            }   else if (_tTradeCycle > (3000000 * _DECIMALFACTOR) && _tTradeCycle <= (4000000 * _DECIMALFACTOR)) {
                _setFees(650);
            } else if (_tTradeCycle > (4000000 * _DECIMALFACTOR) && _tTradeCycle <= (5000000 * _DECIMALFACTOR)) {
                _setFees(700);
            } else if (_tTradeCycle > (5000000 * _DECIMALFACTOR) && _tTradeCycle <= (6000000 * _DECIMALFACTOR)) {
                _setFees(750);
            } else if (_tTradeCycle > (6000000 * _DECIMALFACTOR) && _tTradeCycle <= (7000000 * _DECIMALFACTOR)) {
                _setFees(800);
            } else if (_tTradeCycle > (7000000 * _DECIMALFACTOR) && _tTradeCycle <= (8000000 * _DECIMALFACTOR)) {
                _setFees(850);
            } else if (_tTradeCycle > (8000000 * _DECIMALFACTOR) && _tTradeCycle <= (9000000 * _DECIMALFACTOR)) {
                _setFees(900);
            } else if (_tTradeCycle > (9000000 * _DECIMALFACTOR) && _tTradeCycle <= (10000000 * _DECIMALFACTOR)) {
                _setFees(950);
            } else if (_tTradeCycle > (10000000 * _DECIMALFACTOR) && _tTradeCycle <= (11000000 * _DECIMALFACTOR)) {
                _setFees(1000);
            } else if (_tTradeCycle > (11000000 * _DECIMALFACTOR) && _tTradeCycle <= (12000000 * _DECIMALFACTOR)) {
                _setFees(1050);
            } else if (_tTradeCycle > (12000000 * _DECIMALFACTOR) && _tTradeCycle <= (13000000 * _DECIMALFACTOR)) {
                _setFees(1100);
            } else if (_tTradeCycle > (13000000 * _DECIMALFACTOR) && _tTradeCycle <= (14000000 * _DECIMALFACTOR)) {
                _setFees(1150);
            } else if (_tTradeCycle > (14000000 * _DECIMALFACTOR)) {
                _setFees(1200);
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
    }

    function _transferStandard(address sender, address recipient, uint transferAmount) private {
        uint currentRate =  _getRate();
        (uint rAmount, uint rTransferAmount, uint rFee, uint tTransferAmount, uint transferFee, uint transferBurn) = _getValues(transferAmount);
        uint rBurn =  transferBurn.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _rOwned[feeReceiver] = _rOwned[feeReceiver].add(rFee);

        _burnAndRebase(rBurn, transferFee, transferBurn);
        emit Transfer(sender, recipient, tTransferAmount);

        if (transferFee > 0) {
            emit Transfer(sender, feeReceiver, transferFee);
        }
    }

    function _transferToExcluded(address sender, address recipient, uint transferAmount) private {
        uint currentRate =  _getRate();
        (uint rAmount, uint rTransferAmount, uint rFee, uint tTransferAmount, uint transferFee, uint transferBurn) = _getValues(transferAmount);
        uint rBurn =  transferBurn.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _rOwned[feeReceiver] = _rOwned[feeReceiver].add(rFee);

        _burnAndRebase(rBurn, transferFee, transferBurn);
        emit Transfer(sender, recipient, tTransferAmount);

        if (transferFee > 0) {
            emit Transfer(sender, feeReceiver, transferFee);
        }
    }

    function _transferFromExcluded(address sender, address recipient, uint transferAmount) private {
        uint currentRate =  _getRate();
        (uint rAmount, uint rTransferAmount, uint rFee, uint tTransferAmount, uint transferFee, uint transferBurn) = _getValues(transferAmount);
        uint rBurn =  transferBurn.mul(currentRate);
        _tOwned[sender] = _tOwned[sender].sub(transferAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _rOwned[feeReceiver] = _rOwned[feeReceiver].add(rFee);

        _burnAndRebase(rBurn, transferFee, transferBurn);
        emit Transfer(sender, recipient, tTransferAmount);

        if (transferFee > 0) {
            emit Transfer(sender, feeReceiver, transferFee);
        }
    }

    function _transferBothExcluded(address sender, address recipient, uint transferAmount) private {
        uint currentRate =  _getRate();
        (uint rAmount, uint rTransferAmount, uint rFee, uint tTransferAmount, uint transferFee, uint transferBurn) = _getValues(transferAmount);
        uint rBurn =  transferBurn.mul(currentRate);
        _tOwned[sender] = _tOwned[sender].sub(transferAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _rOwned[feeReceiver] = _rOwned[feeReceiver].add(rFee);

        _burnAndRebase(rBurn, transferFee, transferBurn);
        emit Transfer(sender, recipient, tTransferAmount);

        if (transferFee > 0) {
            emit Transfer(sender, feeReceiver, transferFee);
        }
    }

    function _burnAndRebase(uint rBurn, uint transferFee, uint transferBurn) private {
        _rTotal = _rTotal.sub(rBurn);
        _tFeeTotal = _tFeeTotal.add(transferFee);
        _tBurnTotal = _tBurnTotal.add(transferBurn);
        _tBurnCycle = _tBurnCycle.add(transferBurn).add(transferFee);
        _tTotal = _tTotal.sub(transferBurn);


        // @dev after 1,275,000 tokens burnt, supply is expanded by 500,000 tokens 
        if (_tBurnCycle >= (1275000 * _DECIMALFACTOR)) {
                //set rebase percent
                uint _tRebaseDelta = 500000 * _DECIMALFACTOR;
                _tBurnCycle = _tBurnCycle.sub((1275000 * _DECIMALFACTOR));
                _tTradeCycle = 0;
                _setFees(500);

                _rebase(_tRebaseDelta);
        }
    }

    function burn(uint amount) external override returns (bool) {
        address sender  = _msgSender();
        uint balance = balanceOf(sender);
        require(balance >= amount, "Cannot burn more than on balance");
        require(sender == feeReceiver, "Only feeReceiver");

        uint rBurn =  amount.mul(_getRate());
        _rTotal = _rTotal.sub(rBurn);
        _rOwned[sender] = _rOwned[sender].sub(rBurn);

        _tBurnTotal = _tBurnTotal.add(amount);
        _tTotal = _tTotal.sub(amount);

        emit Transfer(sender, address(0), amount);
        return true;
    }

    function _getValues(uint transferAmount) private view returns (uint, uint, uint, uint, uint, uint) {
        (uint tTransferAmount, uint transferFee, uint transferBurn) = _getTValues(transferAmount, _FOT_FEE, _BURN_FEE);
        (uint rAmount, uint rTransferAmount, uint rFee) = _getRValues(transferAmount, transferFee, transferBurn);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, transferFee, transferBurn);
    }

    function _getTValues(uint transferAmount, uint fotFee, uint burnFee) private pure returns (uint, uint, uint) {
        uint transferFee = ((transferAmount.mul(fotFee)).div(_GRANULARITY)).div(100);
        uint transferBurn = ((transferAmount.mul(burnFee)).div(_GRANULARITY)).div(100);
        uint tTransferAmount = transferAmount.sub(transferFee).sub(transferBurn);
        return (tTransferAmount, transferFee, transferBurn);
    }

    function _getRValues(uint transferAmount, uint transferFee, uint transferBurn) private view returns (uint, uint, uint) {
        uint currentRate =  _getRate();
        uint rAmount = transferAmount.mul(currentRate);
        uint rFee = transferFee.mul(currentRate);
        uint rBurn = transferBurn.mul(currentRate);
        uint rTransferAmount = rAmount.sub(rFee).sub(rBurn);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint) {
        (uint rSupply, uint tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint, uint) {
        uint rSupply = _rTotal;
        uint tSupply = _tTotal;
        for (uint i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }


    function _setFees(uint fee) private {
        require(fee >= 0 && fee <= 1500, "fee should be in 0 - 15%");
        if (_BURN_FEE == fee.div(2)) {
            return;
        }

        _BURN_FEE = fee.div(2);
        _FOT_FEE = fee.div(2);
    }

    function setInitialFee() external onlyOwner() {
        require(!_feeSet, "Initial fee already set");
        _setFees(500);
        _feeSet = true;
    }

    function setMaxCycles(uint _maxCycles) public onlyOwner() {
        require(_maxCycles >= _infinityCycle, "Can not set more than current cycle");
        maxCycles = _maxCycles;
    }

    function getBurnFee() public view returns(uint)  {
        return _BURN_FEE;
    }

    function getFee() public view returns(uint)  {
        return _FOT_FEE;
    }

    function _getMaxTxAmount() private pure returns(uint) {
        return _MAX_TX_SIZE;
    }

    function getCycle() public view returns(uint) {
        return _infinityCycle;
    }

    function getBurnCycle() public view returns(uint) {
        return _tBurnCycle;
    }

    function getTradedCycle() public view returns(uint) {
        return _tTradeCycle;
    }

    function _rebase(uint supplyDelta) internal {
        _infinityCycle = _infinityCycle.add(1);
        _tTotal = _tTotal.add(supplyDelta);

        if (_infinityCycle > maxCycles) {
            _setFees(0);
        }
    }
}
