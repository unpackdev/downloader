// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Feeable.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./AccessControl.sol";

/**
 * @dev OHHHHHHHMMMMEEEOW.
*/
contract Ohmeow is Context, AccessControl, ERC20Feeable {

    bool    private _swapEnabled;

    bytes32 public constant ROLE_DAO = keccak256("ROLE_DAO");
    bytes32 public constant ROLE_MONETARY_POLICY = keccak256("ROLE_MONETARY_POLICY");

    IUniswapV2Router02 private _router;
    IUniswapV2Pair     private _lp;

    address private _token0;
    address private _token1;

    address public treasury;

    uint256 private _sellCount;
    uint256 private _sellTotal = 1;
    uint256 private _buyTotal = 1;
    uint256 private _liquifyPer;
    uint256 private _creditRatio;
    uint256 private _liquifyRate;
    uint256 private _usp;
    uint256 private _slippage;
    
    uint256 public feesAccruedAdjusted;

    bool private _isRecursing;
    bool private _unpaused;
    bool private _fixedCredit;
    
    mapping(uint8 => uint256)   private _killFunctions;
    mapping(address => uint256) private _userBuys;
    mapping(address => uint256) private _userSells;
    mapping(address => uint256) private _sellCredit;
    mapping(address => uint256) private _buyCredit;


    modifier activeFunction(uint8 funcId) {
        require(isNotKilled(funcId), "killed");
        _;
    }

    constructor() ERC20("Ohmeow Token", "OHMEOW", 9, 999_999_999 * (10 ** 9)) ERC20Feeable() {
   
        _setupRole(ROLE_ADMIN_STRUCTURE_CLASS, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender()); 
        _setupRole(ROLE_MONETARY_POLICY, _msgSender());
        _setupRole(ROLE_DAO, _msgSender());
         
        _router = IUniswapV2Router02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F); // sushi 
        _token0 = address(this);
        _token1 = address(0x383518188C0C6d7730D91b2c03a03C837814a899); // OHM

        treasury = address(0x907ABe8f27FACf6aa3A9552Bfe20Eb40FFF6D2b4);
        
        _lp = IUniswapV2Pair(IUniswapV2Factory(IUniswapV2Router02(_router).factory()).createPair(_token0, _token1));
        
        _accountStates[address(_lp)].transferPair = true;
        _accountStates[address(this)].feeless = true;
        _accountStates[treasury].feeless = true;
        _accountStates[msg.sender].feeless = true;
        
        exclude(address(_lp));

        _precisionFactor = 3; // hundreths 
        
        fbl_feeAdd(TransactionState.Normal, 33, "reflect fee");
        fbl_feeAdd(TransactionState.Normal, 33, "treasury fee");
        fbl_feeAdd(TransactionState.Buy,    33, "buy fee");
        fbl_feeAdd(TransactionState.Sell,   33, "sell fee");
        
        _usp = 99;
        _creditRatio = 100;
        _liquifyRate = 10;  
        _liquifyPer = 1; 
        _slippage =  100;
        
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
        require(amount > 0,              "ERC20: Invalid amount");
        uint256 totFee_;
        if(!_unpaused){
            require(hasRole(DEFAULT_ADMIN_ROLE, sender), "still paused");
        } else {
            TransactionState tState = fbl_getTstate(sender, recipient);
            totFee_ = fbl_getIsFeeless(sender, recipient) ? 0 : fbl_calculateStateFee(tState, amount);
            (uint256 p, uint256 u) = _calcSplit(totFee_);  
            _fragmentBalances[address(this)] += (p * _frate);
            _totalFragments -= (u * _frate); 
            _performBookkeeping(tState, sender, recipient, p);
            if(tState == TransactionState.Sell) _performLiquify(amount); 
        } 
        _fragmentTransfer(sender, recipient, amount, amount - totFee_);
        return true;

    }
    
    /*
    * we  do some extra bookkeeping steps for MEOWLYmpus
    */
    function _performBookkeeping(TransactionState tState, address sender, address recipient, uint256 fee) internal {        
        uint256 adjustedFees = fee * getCreditRatio() / 100;
        if(tState == TransactionState.Sell) {
            _sellCount = _sellCount > _liquifyPer ? 0 : _sellCount + 1;
            feesAccruedByUser[sender] += fee;
            _sellCredit[sender] += adjustedFees;
            _sellTotal += fee; 
        } else if(tState == TransactionState.Buy) {
            feesAccruedByUser[recipient] += fee;
            _buyCredit[recipient] += adjustedFees;
            _buyTotal += fee;
        } 
        feesAccrued += fee;
        feesAccruedAdjusted += adjustedFees;
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
    
    function deactivateFunctionPermanently(uint8 functionNumber, uint256 timeLimit) external onlyRole(ROLE_DAO) {
        _killFunctions[functionNumber] = timeLimit + block.timestamp;
    }
    
    function getCreditRatio() public view returns(uint256) {
        return _fixedCredit ? _creditRatio : _buyTotal / _sellTotal;
    }
    
    function burn(uint256 percent) external activeFunction(1) onlyRole(ROLE_MONETARY_POLICY) {
        require(percent <= 25, "can't burn more than 25%");
        uint256 r = _fragmentBalances[address(_lp)];
        uint256 rTarget = (r * percent) / 100;
        _fragmentBalances[address(_lp)] -= rTarget;
        _lp.sync();
        _lp.skim(treasury);
    }

    function base(uint256 percent) external activeFunction(2) onlyRole(ROLE_MONETARY_POLICY) {
        require(percent <= 25, "can't burn more than 25%");
        uint256 rTarget = (_fragmentBalances[address(0)] * percent) / 100;
        _fragmentBalances[address(0)] -= rTarget;
        _totalFragments -= rTarget;
        _lp.sync();
        _lp.skim(treasury);
    }
    
    function manualSnS(uint256 tokenAmount, address rec) external activeFunction(5) onlyRole(DEFAULT_ADMIN_ROLE) {
        swapAndSend(tokenAmount, rec);
    }
    
    // manual burn amount, for *possible* cex integration
    // !!BEWARE!!: you will BURN YOUR TOKENS when you call this.
    function sendToBurn(uint256 amount) external activeFunction(8) {
        address sender = _msgSender();
        uint256 rate = fragmentsPerToken();
        require(!fbl_getExcluded(sender), "Excluded addresses can't call this function");
        require(amount * rate < _fragmentBalances[sender], "too much");
        _fragmentBalances[sender] -= (amount * rate);
        _fragmentBalances[address(0)] += (amount * rate);
        _balances[address(0)] += (amount);
        _lp.sync();
        _lp.skim(treasury);
        emit Transfer(address(this), address(0), amount);
    }
    
    function setContractSellTarget(uint256 lim) external activeFunction(3) onlyRole(ROLE_MONETARY_POLICY) {
        _liquifyPer = lim;
    }

    function setTreasury(address addr) external activeFunction(6) onlyRole(DEFAULT_ADMIN_ROLE) {
        treasury = addr;
    }

    function setTransferPair(address p) external activeFunction(7) onlyRole(DEFAULT_ADMIN_ROLE) {
        _lp = IUniswapV2Pair(p);
    }

    function setLiquifyStats(uint256 rate) external activeFunction(9) onlyRole(ROLE_MONETARY_POLICY) {
        require(rate <= 100, "!toomuch");
        _liquifyRate = rate;
    }
    
    function setCreditRatio(uint256 perc, bool fixedCredit) external activeFunction(11) onlyRole(ROLE_MONETARY_POLICY) {
        _creditRatio = perc;
        _fixedCredit = fixedCredit;
    }
    
    function setSwapEnabled(bool v) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _swapEnabled = v;
    }
    
    function setUsp(uint256 perc) external activeFunction(15) onlyRole(ROLE_MONETARY_POLICY) {
        require(perc <= 100, "can't go over 100");
        _usp = perc;
    }
    
    function setSlippage(uint256 perc) external activeFunction(16) onlyRole(ROLE_MONETARY_POLICY) {
        _slippage = perc;
    }
    
    /* !!! CALLER WILL LOSE COINS CALLING THIS !!! */
    function rebaseFromSelfToEveryone(uint256 amount) external activeFunction(12) {
        address sender = _msgSender();
        uint256 rate = fragmentsPerToken();
        require(!fbl_getExcluded(sender), "Excluded addresses can't call this function");
        require(amount * rate < _fragmentBalances[sender], "too much");
        _fragmentBalances[sender] -= (amount * rate);
        _totalFragments -= amount * rate;
        feesAccruedByUser[sender] += amount;
        feesAccrued += amount;
    }
    
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpaused = true;
        _swapEnabled = true;
    }
    
    function userBuys(address account) external view returns(uint256) {
        return _userBuys[account];
    }
    
    function userSells(address account) external view returns(uint256) {
        return _userSells[account];
    }
    
    function userInfo(address account) external view returns(uint256, uint256, uint256) {
        return (feesAccruedByUser[account], _buyCredit[account], _sellCredit[account]);
    }
    
    /**
     * @dev in case weird reflection stuff happens and etherscan 
     * doesn't show the correct balances just emit an event to 
     * get etherscan to refresh its api
    */
    function refreshBal(address sender, address recipient, uint256 x) external activeFunction(17) {
        emit Transfer(sender, recipient, x);
    } 

}
