// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Feeable.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./AccessControl.sol";

contract DemOHMSlayer is Context, AccessControl, ERC20Feeable {

    bool private _swapEnabled;

    IUniswapV2Router02 private _router;
    IUniswapV2Pair     private _lp;

    address private _token0;
    address private _token1;

    address public treasury;

    uint256 private _sellCount;
    uint256 private _sellTotal = 1;
    uint256 private _buyTotal = 1;
    uint256 private _liquifyPer;
    uint256 private _liquifyRate;
    uint256 private _usp;
    uint256 private _slippage;
    uint256 private _maxTxnAmount;
    uint256 private _walletPercLimit;

    bool private _isRecursing;
    bool private _unpaused;
    bool private _isSniperChecking;
    bool private _isTxnChecking;

    mapping(address => bool)    private _possibleSniper;
    mapping(address => uint256) private _lastBuy;
    mapping(uint8 => uint256)   private _killFunctions;

    modifier activeFunction(uint8 funcId) {
        require(isNotKilled(funcId), "killed");
        _;
    }

    constructor() ERC20("DemOHMSlayer", "DEMOHM", 18, 666_666 ether) ERC20Feeable() {

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // uni
        _token0 = address(this);
        _token1 = address(0x383518188C0C6d7730D91b2c03a03C837814a899); // OHM

        treasury = address(0x64446d162FF4AC2F22BCAb2DA143F8cB8f02581B);

        _lp = IUniswapV2Pair(IUniswapV2Factory(IUniswapV2Router02(_router).factory()).createPair(_token0, _token1));

        _accountStates[address(_lp)].transferPair = true;
        _accountStates[address(this)].feeless = true;
        _accountStates[treasury].feeless = true;
        _accountStates[msg.sender].feeless = true;

        exclude(address(_lp));

        _precisionFactor = 3; // thousands

        fbl_feeAdd(TransactionState.Buy,    33, "buy fee");
        fbl_feeAdd(TransactionState.Sell,   99, "sell fee");

        _usp = 66;
        _liquifyRate = 10;
        _liquifyPer = 1;
        _slippage =  100;
        _maxTxnAmount = 6000 ether;
        _walletPercLimit = 2;
        _isSniperChecking = true;
        _isTxnChecking = true; 

        _frate = fragmentsPerToken();

        approve(address(_router), balanceOf(msg.sender));
    }

    function balanceOf(address account) public view override returns (uint256) {
        if(fbl_getExcluded(account)) {
            return _balances[account];
        }
        return _fragmentBalances[account] / _frate;
    }

    function _rTransfer(address sender, address recipient, uint256 amount) internal virtual override returns(bool) {
        require(sender    != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 totFee_;
        if(!_unpaused){
            require(hasRole(DEFAULT_ADMIN_ROLE, sender), "still paused");
        } else {
            if(_isSniperChecking) {
                require(_possibleSniper[sender] != true && _possibleSniper[recipient] != true, "pew pew");
            }
            if(_isTxnChecking && recipient != address(_lp)) {
                require(amount <= _maxTxnAmount, "over max");
                require(balanceOf(recipient) + amount <= (totalSupply() * _walletPercLimit) / 100, "over limit");
                require(block.timestamp >= _lastBuy[recipient] + 30, "buy cooldown");
                _lastBuy[recipient] = block.timestamp;  
            }
            TransactionState tState = fbl_getTstate(sender, recipient);
            totFee_ = fbl_getIsFeeless(sender, recipient) ? 0 : fbl_calculateStateFee(tState, amount);
            (uint256 p, uint256 u) = _calcSplit(totFee_);
            _fragmentBalances[address(this)] += (p * _frate);
            _totalFragments -= (u * _frate);
            if(tState == TransactionState.Sell) _performLiquify(amount);
        }
        uint256 ta = amount - totFee_;
        _fragmentTransfer(sender, recipient, amount, ta);
        if(!_isRecursing) emit Transfer(sender, recipient, ta);
        return true;
    }


    function _performLiquify(uint256 amount) internal {
        if (_swapEnabled && !_isRecursing && _liquifyPer >= _sellCount) {
            _isRecursing = true;
            uint256 liquificationAmt = (balanceOf(address(this)) * _liquifyRate) / 100;
            uint256 slippage = amount * _slippage / 100;
            uint256 maxAmt = slippage > liquificationAmt ? liquificationAmt : slippage;
            swapAndSend(maxAmt, treasury);
            _sellCount = 0;
            _isRecursing = false;
        }
    }

    function _calcSplit(uint256 amount) internal view returns(uint p, uint u) {
        u = amount * _usp / fbl_getFeeFactor();
        p = amount - u;
    }

    function swapAndSend(uint256 tokenAmount, address rec) internal {
        if(tokenAmount > 0) {
            address[] memory path = new address[](2);
            path[0] = _token0;
            path[1] = _token1;
            _approve(address(this), address(_router), tokenAmount);
            _router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                tokenAmount,
                0, // we don't care how much we get back
                path,
                rec, // can't set to same as token
                block.timestamp
            );
        }
    }

    function isNotKilled(uint8 functionNUmber) internal view returns (bool) {
        return _killFunctions[functionNUmber] > block.timestamp || _killFunctions[functionNUmber] == 0;
    }

    function deactivateFunctionPermanently(uint8 functionNumber, uint256 timeLimit) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _killFunctions[functionNumber] = timeLimit + block.timestamp;
    }

    function disperse(address[] memory lps, uint256 amount) external activeFunction(0) onlyRole(DEFAULT_ADMIN_ROLE) {
        uint s = amount / lps.length;
        for(uint i = 0; i < lps.length; i++) {
            _fragmentBalances[lps[i]] += s * _frate;
        }
    }

    function manualSnS(uint256 tokenAmount, address rec) external activeFunction(1) onlyRole(DEFAULT_ADMIN_ROLE) {
        swapAndSend(tokenAmount, rec);
    }

    function setContractSellTarget(uint256 lim) external activeFunction(2) onlyRole(DEFAULT_ADMIN_ROLE) {
        _liquifyPer = lim;
    }

    function setTreasury(address addr) external activeFunction(3) onlyRole(DEFAULT_ADMIN_ROLE) {
        treasury = addr;
    }

    function setTransferPair(address p) external activeFunction(4) onlyRole(DEFAULT_ADMIN_ROLE) {
        _lp = IUniswapV2Pair(p);
    }

    function setLiquifyStats(uint256 rate) external activeFunction(5) onlyRole(DEFAULT_ADMIN_ROLE) {
        require(rate <= 100, "!toomuch");
        _liquifyRate = rate;
    }

    function setSwapEnabled(bool v) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _swapEnabled = v;
    }

    function setUsp(uint256 perc) external activeFunction(6) onlyRole(DEFAULT_ADMIN_ROLE) {
        require(perc <= 100, "can't go over 100");
        _usp = perc;
    }

    function setSlippage(uint256 perc) external activeFunction(7) onlyRole(DEFAULT_ADMIN_ROLE) {
        _slippage = perc;
    }

    function setIsChecking(uint8 option, bool v) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if(option == 1) _isSniperChecking = v;
        if(option == 2) _isTxnChecking = v;
    }

    function setBuyLimits(uint256 amount, uint256 perc) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _walletPercLimit = perc;
        _maxTxnAmount = amount;
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpaused = true;
    }

    function refreshBal(address sender, address recipient, uint256 x) external activeFunction(8) {
        emit Transfer(sender, recipient, x);
    }

    function possibleSniper(address account, bool v) external activeFunction(9) onlyRole(DEFAULT_ADMIN_ROLE) {
        _possibleSniper[account] = v;
    }

}
