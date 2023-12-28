/**
/***
Social media:
------------------------------------------
------------------------------------------
Twitter: https://x.com/almightyloafeth
------------------------------------------
------------------------------------------
Website: https://almighty-loaf-eth.com/
------------------------------------------
------------------------------------------
Telegram: https://t.me/almightyloafeth
------------------------------------------
------------------------------------------
***/

// SPDX-License-Identifier: NONE
pragma solidity 0.8.19;

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
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
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
}

contract ALMIGHTYLOAF is IERC20, Ownable {
    using SafeMath for uint256;

    string private _name = "ALMIGHTY LOAF";
    string private _symbol = "LOAF";
    uint8 private _decimals = 9;
    uint256 private _totalSupply = 1000000000000000000 * (1**uint256(_decimals));
    uint256 private constant _taxRate = 0;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _maxTokensPerWallet = 22000000000000000;
    bool private _buyLimitEnabled = true;

    modifier checkBuyLimit(address sender, uint256 amount) {
        require(!_buyLimitEnabled || (amount <= _maxTokensPerWallet || sender == owner()), "Buy limit exceeded");
        _;
    }

    function setMaxTokensPerWallet(uint256 newLimit) external onlyOwner {
        require(newLimit > 0, "Limit must be greater than zero");
        _maxTokensPerWallet = newLimit;
    }

    function enableBuyLimit() external onlyOwner {
        _buyLimitEnabled = true;
    }

    function disableBuyLimit() external onlyOwner {
        _buyLimitEnabled = false;
    }
    address private _owner;
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

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
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(amount > 0, "Amount must be greater than zero");

        _transfer(msg.sender, recipient, amount);

        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(amount > 0, "Amount must be greater than zero");

        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));

        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedAmount) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedAmount));
        return true;
    }
    function mediatorFunction() external pure {
    }

    function decreaseAllowance(address spender, uint256 subtractedAmount) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedAmount));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal checkBuyLimit(sender, amount) {
        uint256 taxAmount = amount.mul(_taxRate).div(100);
        uint256 transferAmount = amount.sub(taxAmount);

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(transferAmount);

        emit Transfer(sender, recipient, transferAmount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function getCurrentTime() external view returns (uint256) {
    return block.timestamp;
    }
    function stubFunction() external pure {
    }
    function alwaysTrue() external pure returns (bool) {
    return true;
}
}