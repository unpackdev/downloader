// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.2;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./IWETH.sol";

contract DRF is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isReflectExcluded;
    address[] private _reflectExcluded;
    mapping(address => bool) private _isNoFee;
    mapping(address => bool) private _transferPairAddress;
    uint256 private constant MAX = uint256(- 1);
    uint256 private constant _tTotal = 10000000e18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    enum TransferState {Normal, Buy, Sell}

    /// @notice Principal supply to generate rewards for LP or liquidity
    /// @dev The actual supply is in this contract
    uint256 public principalSupply;
    /// @notice Reserve supply used to generate liquidity
    /// @dev The actual supply is in lord contract
    uint256 public reserveSupply;
    /// @notice Bonus supply used as buy bonus
    /// @dev The actual supply is in lord contract
    uint256 public bonusSupply;

    uint256 public reflectFeeDenominator = 67;
    uint256 public buyTxFeeDenominator = 200;
    uint256 public sellTxFeeDenominator = 200;
    uint256 public buyBonusDenominator = 25;
    uint256 public sellFeeDenominator = 50;

    /// @dev Restrict buy max, set to 0 to remove restriction
    uint256 public restrictBuyAmount = 8000e18;

    address public lord;
    address public pairAddress;

    struct TValues {
        uint256 amount;
        uint256 transferAmount;
        uint256 fee;
        uint256 txFee;
        uint256 sellFee;
        uint256 buyBonus;
    }

    struct RValues {
        uint256 amount;
        uint256 transferAmount;
        uint256 fee;
        uint256 txFee;
        uint256 sellFee;
        uint256 buyBonus;
    }

    string private _name = 'drift.finance';
    string private _symbol = 'DRF';
    uint8 private _decimals = 18;

    constructor () public {
    }

    receive() external payable {
    }

    /* ========== Modifiers ========== */

    modifier onlyLord {
        require(_msgSender() == lord, "Lord only");
        _;
    }

    /* ========== Only Owner ========== */

    function init(address _lord, address _pairAddress) external onlyOwner {
        if (lord == address(0)) {
            lord = _lord;
            pairAddress = _pairAddress;

            _rOwned[lord] = _rTotal;
            setNoFee(lord, true);
            excludeReflectAccount(lord);
            excludeReflectAccount(pairAddress);

            // Set transfer pair address so contract know which one is buy or sell
            setTransferPairAddress(pairAddress, true);

            // Set no fee since we use this contract as principal to generate rewards for LP provider
            setNoFee(address(this), true);
        }
    }

    function setNoFee(address account, bool value) public onlyOwner {
        _isNoFee[account] = value;
    }

    function setTransferPairAddress(address transferPairAddress, bool value) public onlyOwner {
        _transferPairAddress[transferPairAddress] = value;
    }

    function setRestrictBuyAmount(uint256 amount) external onlyOwner {
        restrictBuyAmount = amount;
    }

    function excludeReflectAccount(address account) public onlyOwner {
        require(!_isReflectExcluded[account], "Already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isReflectExcluded[account] = true;
        _reflectExcluded.push(account);
    }

    function includeReflectAccount(address account) public onlyOwner {
        require(_isReflectExcluded[account], "Already included");
        for (uint256 i = 0; i < _reflectExcluded.length; i++) {
            if (_reflectExcluded[i] == account) {
                _reflectExcluded[i] = _reflectExcluded[_reflectExcluded.length - 1];
                _tOwned[account] = 0;
                _isReflectExcluded[account] = false;
                _reflectExcluded.pop();
                break;
            }
        }
    }

    /* ========== Only Lord ========== */

    function setFee(
        uint256 _reflectFeeDenominator,
        uint256 _buyTxFeeDenominator,
        uint256 _sellTxFeeDenominator,
        uint256 _buyBonusDenominator,
        uint256 _sellFeeDenominator
    ) external onlyLord {
        reflectFeeDenominator = _reflectFeeDenominator;
        buyTxFeeDenominator = _buyTxFeeDenominator;
        sellTxFeeDenominator = _sellTxFeeDenominator;
        buyBonusDenominator = _buyBonusDenominator;
        sellFeeDenominator = _sellFeeDenominator;
    }

    function setReserveSupply(uint256 amount) external onlyLord {
        reserveSupply = amount;
    }

    /// @notice Deposit principal supply from lord
    function depositPrincipalSupply(uint256 amount) external onlyLord {
        principalSupply = amount;
        _transferFromExcluded(lord, address(this), principalSupply, false, TransferState.Normal);
    }

    /// @notice Withdraw back principal supply to lord
    function withdrawPrincipalSupply() external onlyLord returns(uint256) {
        _transferToExcluded(address(this), lord, balanceOf(address(this)), false, TransferState.Normal);
        return principalSupply;
    }

    /// @notice Reward LP providers if pair address is specified, otherwise just add the reward to reserve supply for liquidity
    function distributePrincipalRewards(address rewardPairAddress) external onlyLord {
        uint256 balance = balanceOf(address(this));
        if (balance > 0) {
            uint256 reward = balance.sub(principalSupply);
            // If pair address specified then reward LP provider
            if (rewardPairAddress != address(0)) {
                _transferToExcluded(address(this), rewardPairAddress, reward, false, TransferState.Normal);
                IUniswapV2Pair(rewardPairAddress).sync();
            }
            // else add as reserve supply to generate liquidity
            else {
                _transferToExcluded(address(this), lord, reward, false, TransferState.Normal);
                reserveSupply = reserveSupply.add(reward);
            }
        }
    }

    /* ========== View ========== */

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

    function circulatingSupply() public view returns (uint256) {
        return _tTotal.sub(balanceOf(address(this))).sub(balanceOf(lord));
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isReflectExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function isExcluded(address account) public view returns (bool) {
        return _isReflectExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee, TransferState transferState) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (RValues memory r,) = _getValues(tAmount, true, transferState);
            return r.amount;
        } else {
            (RValues memory r,) = _getValues(tAmount, true, transferState);
            return r.transferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    /* ========== Mutative ========== */

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

    function reflect(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isReflectExcluded[sender], "Excluded addresses cannot call this function");
        (RValues memory r,) = _getValues(tAmount, !_isNoFee[sender], TransferState.Normal);
        _rOwned[sender] = _rOwned[sender].sub(r.amount);
        _rTotal = _rTotal.sub(r.amount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    /* ========== Private ========== */

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Invalid amount");

        bool hasFee = !_isNoFee[sender] && !_isNoFee[recipient];
        TransferState transferState;
        if (_transferPairAddress[sender]) {
            transferState = TransferState.Buy;
        } else if (_transferPairAddress[recipient]) {
            transferState = TransferState.Sell;
        }
        if (restrictBuyAmount > 0 && transferState == TransferState.Buy && hasFee) {
            require(amount <= restrictBuyAmount, "Buy restricted");
        }
        if (_isReflectExcluded[sender] && !_isReflectExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount, hasFee, transferState);
        } else if (!_isReflectExcluded[sender] && _isReflectExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount, hasFee, transferState);
        } else if (!_isReflectExcluded[sender] && !_isReflectExcluded[recipient]) {
            _transferStandard(sender, recipient, amount, hasFee, transferState);
        } else if (_isReflectExcluded[sender] && _isReflectExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount, hasFee, transferState);
        } else {
            _transferStandard(sender, recipient, amount, hasFee, transferState);
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount, bool hasFee, TransferState transferState) private {
        (RValues memory r, TValues memory t) = _getValues(tAmount, hasFee, transferState);
        _rOwned[sender] = _rOwned[sender].sub(r.amount);
        _rOwned[recipient] = _rOwned[recipient].add(r.transferAmount.add(r.buyBonus));

        _tOwned[lord] = _tOwned[lord].add(t.txFee.add(t.sellFee)).sub(t.buyBonus);
        _rOwned[lord] = _rOwned[lord].add(r.txFee.add(r.sellFee)).sub(r.buyBonus);
        reserveSupply = reserveSupply.add(t.txFee);
        bonusSupply = bonusSupply.add(t.sellFee).sub(t.buyBonus);

        _reflectFee(r.fee, t.fee);
        emit Transfer(sender, recipient, t.transferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount, bool hasFee, TransferState transferState) private {
        (RValues memory r, TValues memory t) = _getValues(tAmount, hasFee, transferState);
        _rOwned[sender] = _rOwned[sender].sub(r.amount);
        _tOwned[recipient] = _tOwned[recipient].add(t.transferAmount.add(t.buyBonus));
        _rOwned[recipient] = _rOwned[recipient].add(r.transferAmount.add(r.buyBonus));

        _tOwned[lord] = _tOwned[lord].add(t.txFee.add(t.sellFee)).sub(t.buyBonus);
        _rOwned[lord] = _rOwned[lord].add(r.txFee.add(r.sellFee)).sub(r.buyBonus);
        reserveSupply = reserveSupply.add(t.txFee);
        bonusSupply = bonusSupply.add(t.sellFee).sub(t.buyBonus);

        _reflectFee(r.fee, t.fee);
        emit Transfer(sender, recipient, t.transferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount, bool hasFee, TransferState transferState) private {
        (RValues memory r, TValues memory t) = _getValues(tAmount, hasFee, transferState);
        _tOwned[sender] = _tOwned[sender].sub(t.amount);
        _rOwned[sender] = _rOwned[sender].sub(r.amount);
        _rOwned[recipient] = _rOwned[recipient].add(r.transferAmount.add(r.buyBonus));

        _tOwned[lord] = _tOwned[lord].add(t.txFee.add(t.sellFee)).sub(t.buyBonus);
        _rOwned[lord] = _rOwned[lord].add(r.txFee.add(r.sellFee)).sub(r.buyBonus);
        reserveSupply = reserveSupply.add(t.txFee);
        bonusSupply = bonusSupply.add(t.sellFee).sub(t.buyBonus);

        _reflectFee(r.fee, t.fee);
        emit Transfer(sender, recipient, t.transferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount, bool hasFee, TransferState transferState) private {
        (RValues memory r, TValues memory t) = _getValues(tAmount, hasFee, transferState);
        _tOwned[sender] = _tOwned[sender].sub(t.amount);
        _rOwned[sender] = _rOwned[sender].sub(r.amount);
        _tOwned[recipient] = _tOwned[recipient].add(t.transferAmount.add(t.buyBonus));
        _rOwned[recipient] = _rOwned[recipient].add(r.transferAmount.add(r.buyBonus));

        _tOwned[lord] = _tOwned[lord].add(t.txFee.add(t.sellFee)).sub(t.buyBonus);
        _rOwned[lord] = _rOwned[lord].add(r.txFee.add(r.sellFee)).sub(r.buyBonus);
        reserveSupply = reserveSupply.add(t.txFee);
        bonusSupply = bonusSupply.add(t.sellFee).sub(t.buyBonus);

        _reflectFee(r.fee, t.fee);
        emit Transfer(sender, recipient, t.transferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount, bool hasFee, TransferState transferState) private view returns (RValues memory r, TValues memory t) {
        t = _getTValues(tAmount, hasFee, transferState);
        r = _getRValues(t, _getRate());
    }

    function _getTValues(uint256 tAmount, bool hasFee, TransferState transferState) private view returns (TValues memory t) {
        t.amount = tAmount;
        if (hasFee) {
            t.fee = tAmount.div(reflectFeeDenominator);
            t.txFee = transferState == TransferState.Buy ? tAmount.div(buyTxFeeDenominator) : tAmount.div(sellTxFeeDenominator);
            t.sellFee = transferState == TransferState.Sell ? tAmount.div(sellFeeDenominator) : 0;
            t.buyBonus = transferState == TransferState.Buy ? tAmount.div(buyBonusDenominator) : 0;
            if (t.buyBonus > 0) {
                t.buyBonus = bonusSupply > t.buyBonus ? t.buyBonus : bonusSupply;
            }
        }
        t.transferAmount = tAmount.sub(t.fee).sub(t.txFee).sub(t.sellFee);
    }

    function _getRValues(TValues memory t, uint256 currentRate) private pure returns (RValues memory r) {
        r.amount = t.amount.mul(currentRate);
        r.fee = t.fee.mul(currentRate);
        r.txFee = t.txFee.mul(currentRate);
        r.sellFee = t.sellFee.mul(currentRate);
        r.transferAmount = r.amount.sub(r.fee).sub(r.txFee).sub(r.sellFee);
        r.buyBonus = t.buyBonus.mul(currentRate);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _reflectExcluded.length; i++) {
            if (_rOwned[_reflectExcluded[i]] > rSupply || _tOwned[_reflectExcluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_reflectExcluded[i]]);
            tSupply = tSupply.sub(_tOwned[_reflectExcluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

}