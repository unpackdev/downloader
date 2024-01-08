// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

library ShuffleConstants {
    string private constant _name = "SHUFFLE!";
    string private constant _symbol = "SHFL";
    uint8 private constant _decimals = 18;
    address private constant _tokenOwner = 0xb82EC3578dA0DAD284E4C60a45C52F95186E929A;
    uint256 private constant _unlockMultiple = 5;
    uint256 private constant _maxLock = 20 * 24 * 60 * 60;

    function getName() internal pure returns (string memory) {
        return _name;
    }

    function getSymbol() internal pure returns (string memory) {
        return _symbol;
    }

    function getDecimals() internal pure returns (uint8) {
        return _decimals;
    }

    function getTokenOwner() internal pure returns (address) {
        return _tokenOwner;
    }

    function getUnlockMultiple() internal pure returns (uint256) {
        return _unlockMultiple;
    }

    function getMaxLock() internal pure returns (uint256) {
        return _maxLock;
    }

}

contract Shuffle is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    uint256 _totalSupply = 10**8 * 10**18;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    IUniswapV2Router02 public uniRouter;
    IUniswapV2Factory public uniFactory;
    address public launchPool;

    uint256 private _tradingTime;
    uint256 private _restrictionLiftTime;
    uint256 private _maxRestrictionAmount;
    uint256 private _restrictionGas;
    uint256 private _launchPrice;    
    mapping (address => bool) private _isWhitelisted;
    mapping (address => bool) private _openSender;
    mapping (address => bool) private _lastTx;
    mapping (address => uint256) public lockTime;
    mapping (address => uint256) public lockedAmount;

    constructor (uint256 _gas, uint256 _amount) public {
        uniRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniFactory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
        launchPool = uniFactory.createPair(address(uniRouter.WETH()),address(this));
        _maxRestrictionAmount = _amount;
        _restrictionGas = _gas;
        _isWhitelisted[0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D] = true;
        _isWhitelisted[launchPool] = true;
        _balances[ShuffleConstants.getTokenOwner()] = _totalSupply; 
        emit Transfer(address(0), ShuffleConstants.getTokenOwner(), _totalSupply);
    }

    function name() public view returns (string memory) {
        return ShuffleConstants.getName();
    }

    function symbol() public view returns (string memory) {
        return ShuffleConstants.getSymbol();
    }

    function decimals() public view returns (uint8) {
        return ShuffleConstants.getDecimals();
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "SHFL: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "SHFL: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private launchRestrict(sender, recipient, amount) {
        require(sender != address(0), "SHFL: transfer from the zero address");
        require(recipient != address(0), "SHFL: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "SHFL: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "SHFL: approve from the zero address");
        require(spender != address(0), "SHFL: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setRestrictionAmount(uint256 amount) external onlyOwner() {
        _maxRestrictionAmount = amount;
    }

    function setRestrictionGas(uint256 price) external onlyOwner() {
        _restrictionGas = price;
    }

    function addSender(address account) external onlyOwner() {
        _openSender[account] = true;
    }

    function setLaunchPrice(uint256 price) external onlyOwner() {
        _launchPrice = price;
    }

    function lockBot(address account, uint256 unlockBotTime) external onlyOwner() {
        lockTime[account] = unlockBotTime;
    }

    modifier launchRestrict(address sender, address recipient, uint256 amount) {
        if (_tradingTime == 0) {
            require(_openSender[sender],"SHFL: transfers are disabled");
            if (recipient == launchPool) {
                _tradingTime = now;
                _restrictionLiftTime = now.add(3*60);
            }
        } else if (_tradingTime == now) {
            revert("SHFL: no transactions allowed");
        } else if (_tradingTime < now && _restrictionLiftTime > now) {
            require(amount <= _maxRestrictionAmount, "SHFL: amount greater than max limit");
            require(tx.gasprice <= _restrictionGas,"SHFL: gas price above limit");
            if (!_isWhitelisted[sender] && !_isWhitelisted[recipient]) {
                require(!_lastTx[sender] && !_lastTx[recipient] && !_lastTx[tx.origin], "SHFL: only one tx in restricted time");
                _lastTx[sender] = true;
                _lastTx[recipient] = true;
                _lastTx[tx.origin] = true;
            } else if (!_isWhitelisted[recipient]){
                require(!_lastTx[recipient] && !_lastTx[tx.origin], "SHFL: only one tx in restricted time");
                _lastTx[recipient] = true;
                _lastTx[tx.origin] = true;
            } else if (!_isWhitelisted[sender]) {
                require(!_lastTx[sender] && !_lastTx[tx.origin], "SHFL: only one tx in restricted time");
                _lastTx[sender] = true;
                _lastTx[tx.origin] = true;
            }

            // If 100 ETH : 8000 Tokens were in pool, price before buy = 0.0125. If 110 ETH : 7200 Tokens
            // after the purchase, price after buy = 0.0153. The ETH will be in the pool by the time of this function
            // execution, but tokens won't decrease yet, so we get to understand the actual execution price here
            // 110 ETH : 8000 Tokens = 0.01375. This logic will be used to understand the multiple and execute vesting 
            // accordingly.
            if (sender == launchPool) {
                require((_isWhitelisted[recipient] || _isWhitelisted[msg.sender]) && !Address.isContract(tx.origin), "SHFL: only uniswap router allowed");
                uint256 ethBal = IERC20(address(uniRouter.WETH())).balanceOf(launchPool);
                uint256 tokenBal = balanceOf(launchPool);
                uint256 curPriceMultiple = (ethBal * 10**18 / tokenBal) * 10**3 / _launchPrice;
                uint256 timeDelay = ShuffleConstants.getMaxLock()*curPriceMultiple/(10**3 * ShuffleConstants.getUnlockMultiple());
                if (timeDelay <= ShuffleConstants.getMaxLock()) {
                    lockTime[recipient] = now.add(ShuffleConstants.getMaxLock().sub(timeDelay));
                }
                uint256 unlockAmount = amount.mul(curPriceMultiple)/(10**3 * ShuffleConstants.getUnlockMultiple());
                if (unlockAmount <= amount) {
                    lockedAmount[recipient] = amount.sub(unlockAmount);
                }
            }
        } else {
            if (!_isWhitelisted[sender] && lockTime[sender] >= now) {
                require(amount.add(lockedAmount[sender]) <= _balances[sender], "SHFL: locked balance");
            }
        }
        _;
    }
}