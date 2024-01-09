// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

import "./IERC20.sol";
import "./RiskPoolERC20.sol";
import "./ISingleSidedReinsurancePool.sol";
import "./IRiskPool.sol";
import "./TransferHelper.sol";

contract RiskPool is IRiskPool, RiskPoolERC20 {
    // ERC20 attributes
    string public name;
    string public symbol;

    address public SSRP;
    address public override currency; // for now we should accept only UNO
    uint256 public override lpPriceUno;
    uint256 public MIN_LP_CAPITAL = 1e20;

    event LogCancelWithdrawRequest(address indexed _user, uint256 _amount, uint256 _amountInUno);
    event LogPolicyClaim(address indexed _user, uint256 _amount);
    event LogMigrateLP(address indexed _user, address indexed _migrateTo, uint256 _unoAmount);
    event LogLeaveFromPending(address indexed _user, uint256 _withdrawLpAmount, uint256 _withdrawUnoAmount);

    constructor(
        string memory _name,
        string memory _symbol,
        address _SSRP,
        address _currency
    ) {
        name = _name;
        symbol = _symbol;
        SSRP = _SSRP;
        currency = _currency;
        lpPriceUno = 1e18;
    }

    modifier onlySSRP() {
        require(msg.sender == SSRP, "UnoRe: RiskPool Forbidden");
        _;
    }

    /**
     * @dev Users can stake only through Cohort
     */
    function enter(address _from, uint256 _amount) external override onlySSRP {
        _mint(_from, (_amount * 1e18) / lpPriceUno);
    }

    /**
     * @param _amount UNO amount to withdraw
     */
    function leaveFromPoolInPending(address _to, uint256 _amount) external override onlySSRP {
        require(totalSupply() > 0, "UnoRe: There's no remaining in the pool");
        uint256 requestAmountInLP = (_amount * 1e18) / lpPriceUno;
        require(
            (requestAmountInLP + uint256(withdrawRequestPerUser[_to].pendingAmount)) <= balanceOf(_to),
            "UnoRe: lp balance overflow"
        );
        _withdrawRequest(_to, requestAmountInLP, _amount);
    }

    function leaveFromPending(address _to) external override onlySSRP returns (uint256, uint256) {
        uint256 cryptoBalance = IERC20(currency).balanceOf(address(this));
        uint256 pendingAmount = uint256(withdrawRequestPerUser[_to].pendingAmount);
        require(cryptoBalance > 0, "UnoRe: zero uno balance");
        require(balanceOf(_to) >= pendingAmount, "UnoRe: lp balance overflow");
        _withdrawImplement(_to);
        uint256 pendingAmountInUno = (pendingAmount * lpPriceUno) / 1e18;
        if (cryptoBalance - MIN_LP_CAPITAL > pendingAmountInUno) {
            TransferHelper.safeTransfer(currency, _to, pendingAmountInUno);
            emit LogLeaveFromPending(_to, pendingAmount, pendingAmountInUno);
            return (pendingAmount, pendingAmountInUno);
        } else {
            TransferHelper.safeTransfer(currency, _to, cryptoBalance - MIN_LP_CAPITAL);
            emit LogLeaveFromPending(_to, pendingAmount, cryptoBalance - MIN_LP_CAPITAL);
            return (((cryptoBalance - MIN_LP_CAPITAL) * 1e18) / lpPriceUno, cryptoBalance - MIN_LP_CAPITAL);
        }
    }

    function cancelWithrawRequest(address _to) external override onlySSRP returns (uint256, uint256) {
        uint256 _pendingAmount = uint256(withdrawRequestPerUser[_to].pendingAmount);
        require(_pendingAmount > 0, "UnoRe: zero amount");
        _cancelWithdrawRequest(_to);
        emit LogCancelWithdrawRequest(_to, _pendingAmount, (_pendingAmount * lpPriceUno) / 1e18);
        return (_pendingAmount, (_pendingAmount * lpPriceUno) / 1e18);
    }

    function policyClaim(address _to, uint256 _amount) external override onlySSRP returns (uint256 realClaimAmount) {
        uint256 cryptoBalance = IERC20(currency).balanceOf(address(this));
        require(totalSupply() > 0, "UnoRe: zero lp balance");
        require(cryptoBalance > MIN_LP_CAPITAL, "UnoRe: minimum UNO capital underflow");
        if (cryptoBalance - MIN_LP_CAPITAL > _amount) {
            TransferHelper.safeTransfer(currency, _to, _amount);
            realClaimAmount = _amount;
            emit LogPolicyClaim(_to, _amount);
        } else {
            TransferHelper.safeTransfer(currency, _to, cryptoBalance - MIN_LP_CAPITAL);
            realClaimAmount = cryptoBalance - MIN_LP_CAPITAL;
            emit LogPolicyClaim(_to, cryptoBalance - MIN_LP_CAPITAL);
        }
        cryptoBalance = IERC20(currency).balanceOf(address(this));
        lpPriceUno = (cryptoBalance * 1e18) / totalSupply(); // UNO value per lp
    }

    function migrateLP(
        address _to,
        address _migrateTo,
        bool _isUnLocked
    ) external override onlySSRP returns (uint256) {
        require(_migrateTo != address(0), "UnoRe: zero address");
        if (_isUnLocked && withdrawRequestPerUser[_to].pendingAmount > 0) {
            uint256 pendingAmountInUno = (uint256(withdrawRequestPerUser[_to].pendingAmount) * lpPriceUno) / 1e18;
            uint256 cryptoBalance = IERC20(currency).balanceOf(address(this));
            if (pendingAmountInUno < cryptoBalance - MIN_LP_CAPITAL) {
                TransferHelper.safeTransfer(currency, _to, pendingAmountInUno);
            } else {
                TransferHelper.safeTransfer(currency, _to, cryptoBalance - MIN_LP_CAPITAL);
            }
            _withdrawImplement(_to);
        } else {
            if (withdrawRequestPerUser[_to].pendingAmount > 0) {
                _cancelWithdrawRequest(_to);
            }
        }
        uint256 unoBalance = (balanceOf(_to) * lpPriceUno) / 1e18;
        TransferHelper.safeTransfer(currency, _migrateTo, unoBalance);
        _burn(_to, balanceOf(_to));
        emit LogMigrateLP(_to, _migrateTo, unoBalance);
        return unoBalance;
    }

    function setMinLPCapital(uint256 _minLPCapital) external override onlySSRP {
        require(_minLPCapital > 0, "UnoRe: not allow zero value");
        MIN_LP_CAPITAL = _minLPCapital;
    }

    function getWithdrawRequest(address _to)
        external
        view
        override
        onlySSRP
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            uint256(withdrawRequestPerUser[_to].pendingAmount),
            uint256(withdrawRequestPerUser[_to].requestTime),
            withdrawRequestPerUser[_to].pendingUno
        );
    }

    function getTotalWithdrawRequestAmount() external view override onlySSRP returns (uint256) {
        return totalWithdrawPending;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(
            balanceOf(msg.sender) - uint256(withdrawRequestPerUser[msg.sender].pendingAmount) >= amount,
            "ERC20: transfer amount exceeds balance or pending WR"
        );
        _transfer(msg.sender, recipient, amount);

        ISingleSidedReinsurancePool(SSRP).lpTransfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        require(
            balanceOf(sender) - uint256(withdrawRequestPerUser[sender].pendingAmount) >= amount,
            "ERC20: transfer amount exceeds balance or pending WR"
        );
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);
        ISingleSidedReinsurancePool(SSRP).lpTransfer(sender, recipient, amount);
        return true;
    }
}
