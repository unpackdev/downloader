// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

contract Ownable {
    address private _owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    
    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }
    
    function owner() public view returns (address) {
        return _owner;
    }
    
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract MaterToken is IERC20, Ownable {
    string public name = "Mater";
    string public symbol = "MATER";
    uint8 public decimals = 18;
    uint256 private _totalSupply;
    address public feeAddress; // Address to receive transfer fees
    uint256 public maxTransferFeeRate = 2; // Maximum 2% transfer fee
    uint256 public maxBurnFeeRate = 2; // Maximum 2% burn fee
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public isExcludedFromFees; // Addresses excluded from fees

    // 2% transfer fee and 1% burn fee
    uint256 public transferFeeRate = 2; // 2%
    uint256 public burnFeeRate = 1; // 1%

    constructor(uint256 initialSupply, address _feeAddress) {
        _totalSupply = initialSupply * 10**uint256(decimals);
        _balances[msg.sender] = _totalSupply;
        feeAddress = _feeAddress;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 fee = (amount * transferFeeRate) / 100;
        uint256 burnAmount = (amount * burnFeeRate) / 100;
        uint256 transferAmount = amount - fee;
        
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[msg.sender] >= amount, "ERC20: transfer amount exceeds balance");
        require(fee <= (amount * maxTransferFeeRate) / 100, "Transfer fee exceeds maximum");
        require(burnAmount <= (amount * maxBurnFeeRate) / 100, "Burn fee exceeds maximum");

        _balances[msg.sender] -= amount;
        _balances[recipient] += transferAmount;
        _burn(msg.sender, burnAmount);
        _transferFee(fee);
        emit Transfer(msg.sender, recipient, transferAmount);
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
        uint256 fee = (amount * transferFeeRate) / 100;
        uint256 burnAmount = (amount * burnFeeRate) / 100;
        uint256 transferAmount = amount - fee;

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");
        require(_allowances[sender][msg.sender] >= amount, "ERC20: transfer amount exceeds allowance");
        require(fee <= (amount * maxTransferFeeRate) / 100, "Transfer fee exceeds maximum");
        require(burnAmount <= (amount * maxBurnFeeRate) / 100, "Burn fee exceeds maximum");

        _balances[sender] -= amount;
        _balances[recipient] += transferAmount;
        _burn(sender, burnAmount);
        _transferFee(fee);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        emit Transfer(sender, recipient, transferAmount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        require(_balances[account] >= amount, "ERC20: burn amount exceeds balance");
        _totalSupply -= amount;
        _balances[account] -= amount;
        emit Transfer(account, address(0), amount);
    }

    function _transferFee(uint256 fee) internal {
        require(feeAddress != address(0), "Fee address not set");
        _balances[feeAddress] += fee;
        emit Transfer(msg.sender, feeAddress, fee);
    }

    // Function to change the transfer fee rate
    function setTransferFeeRate(uint256 newFeeRate) public onlyOwner {
        require(newFeeRate <= 100, "Fee rate cannot exceed 100%");
        transferFeeRate = newFeeRate;
    }

    // Function to change the burn fee rate
    function setBurnFeeRate(uint256 newBurnFeeRate) public onlyOwner {
        require(newBurnFeeRate <= 100, "Burn fee rate cannot exceed 100%");
        burnFeeRate = newBurnFeeRate;
    }

    // Function to change the fee address
    function setFeeAddress(address newFeeAddress) public onlyOwner {
        require(newFeeAddress != address(0), "Fee address cannot be the zero address");
        feeAddress = newFeeAddress;
    }

    // Function to exclude an address from fees
    function excludeFromFees(address account) public onlyOwner {
        isExcludedFromFees[account] = true;
    }

    // Function to include an address in fees
    function includeInFees(address account) public onlyOwner {
        isExcludedFromFees[account] = false;
    }
}