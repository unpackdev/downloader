// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// Safe Math Library
// ----------------------------------------------------------------------------

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

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------

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

// ----------------------------------------------------------------------------
// Ownable Contract
// ----------------------------------------------------------------------------

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid owner address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
}

// ----------------------------------------------------------------------------
// ERC20 Token Contract
// ----------------------------------------------------------------------------

contract MaterToken is IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    address public feeAddress;
    uint256 public transferFeeRate = 2;  // 2% transfer fee
    uint256 public burnFeeRate = 1;      // 1% burn fee
    uint256 public maxTransferAmount = 10000000000 * 10**uint256(18);
    uint256 public globalMaxBalance;

    mapping(address => bool) public isExcludedFromFees;
    mapping(address => bool) public isExcludedFromTransferLimits;
    mapping(address => bool) public isExcludedFromGlobalMaxBalance;

    constructor(uint256 initialSupply, address _feeAddress) {
        _name = "Mater";
        _symbol = "MATER";
        _decimals = 18;

        _mint(msg.sender, initialSupply * 10**uint256(_decimals));
        feeAddress = _feeAddress;

        // Exclude the contract owner (msg.sender) from fees, transfer limits, and global max balance.
        isExcludedFromFees[msg.sender] = true;
        isExcludedFromTransferLimits[msg.sender] = true;
        isExcludedFromGlobalMaxBalance[msg.sender] = true;

        isExcludedFromFees[address(this)] = true;
        isExcludedFromTransferLimits[address(this)] = true;
        isExcludedFromGlobalMaxBalance[address(this)] = true;
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
        require(balanceOf(msg.sender) >= amount, "ERC20: transfer amount exceeds balance");

        uint256 fee = (amount * transferFeeRate) / 100;
        uint256 burnAmount = (amount * burnFeeRate) / 100;
        uint256 transferAmount = amount.sub(fee).sub(burnAmount);

        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(fee <= (amount * transferFeeRate) / 100, "Transfer fee exceeds maximum");
        require(burnAmount <= (amount * burnFeeRate) / 100, "Burn fee exceeds maximum");

        // Allow the contract owner to send tokens without any checks
        if (msg.sender != owner) {
            require(amount <= maxTransferAmount, "Amount exceeds maximum transfer amount");
            require(balanceOf(recipient) + transferAmount <= globalMaxBalance, "Recipient's balance would exceed the maximum allowed");
        }

        _transfer(msg.sender, recipient, transferAmount);
        _burn(msg.sender, burnAmount);
        _transferFee(fee);

        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(balanceOf(sender) >= amount, "ERC20: transfer amount exceeds balance");

        uint256 fee = (amount * transferFeeRate) / 100;
        uint256 burnAmount = (amount * burnFeeRate) / 100;
        uint256 transferAmount = amount.sub(fee).sub(burnAmount);

        require(fee <= (amount * transferFeeRate) / 100, "Transfer fee exceeds maximum");
        require(burnAmount <= (amount * burnFeeRate) / 100, "Burn fee exceeds maximum");

        // Allow the contract owner to send tokens without any checks
        if (msg.sender != owner) {
            require(amount <= maxTransferAmount, "Amount exceeds maximum transfer amount");
            require(balanceOf(recipient) + transferAmount <= globalMaxBalance, "Recipient's balance would exceed the maximum allowed");
        }

        _transfer(sender, recipient, transferAmount);
        _burn(sender, burnAmount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance.sub(subtractedValue));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(balanceOf(sender) >= amount, "ERC20: transfer amount exceeds balance");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        require(balanceOf(account) >= amount, "ERC20: burn amount exceeds balance");

        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transferFee(uint256 fee) internal {
        require(feeAddress != address(0), "Fee address not set");
        _transfer(msg.sender, feeAddress, fee);
    }

    // Functions for managing fees and limits
    function setFeeAddress(address newFeeAddress) public onlyOwner {
        require(newFeeAddress != address(0), "Fee address cannot be the zero address");
        feeAddress = newFeeAddress;
    }

    function setTransferFeeRate(uint256 newFeeRate) public onlyOwner {
        require(newFeeRate <= 3, "Fee rate cannot exceed 3%");
        transferFeeRate = newFeeRate;
    }

    function setBurnFeeRate(uint256 newBurnFeeRate) public onlyOwner {
        require(newBurnFeeRate <= 2, "Burn fee rate cannot exceed 2%");
        burnFeeRate = newBurnFeeRate;
    }

    function setMaxTransferAmount(uint256 newMaxTransferAmount) public onlyOwner {
        maxTransferAmount = newMaxTransferAmount;
    }

    function setGlobalMaxBalance(uint256 newGlobalMaxBalance) public onlyOwner {
        globalMaxBalance = newGlobalMaxBalance;
    }

    // Functions for excluding addresses from fees and limits
    function excludeFromFees(address account) public onlyOwner {
        isExcludedFromFees[account] = true;
    }

    function includeInFees(address account) public onlyOwner {
        isExcludedFromFees[account] = false;
    }

    function excludeFromTransferLimits(address account) public onlyOwner {
        isExcludedFromTransferLimits[account] = true;
    }

    function includeInTransferLimits(address account) public onlyOwner {
        isExcludedFromTransferLimits[account] = false;
    }

    function excludeFromGlobalMaxBalance(address account) public onlyOwner {
        isExcludedFromGlobalMaxBalance[account] = true;
    }

    function includeInGlobalMaxBalance(address account) public onlyOwner {
        isExcludedFromGlobalMaxBalance[account] = false;
    }
}