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

contract SmurfCat is IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    uint256 private _totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;
    address public owner;
    
    // 5% transaction fee
    uint256 public constant feePercent = 5;
    
    constructor() {
        name = "SmurfCat";
        symbol = "SMURF";
        decimals = 18;
        owner = msg.sender;
        
        // Initial Supply - 10 million tokens
        _totalSupply = 10000000 * 10 ** uint256(decimals);
        
        // 10% of initial supply goes to creator
        uint256 creatorSupply = _totalSupply / 10;
        _balances[owner] = creatorSupply;
        
        emit Transfer(address(0), owner, creatorSupply);
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

    function allowance(address _owner, address spender) public view override returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");

        uint256 fee = amount * feePercent / 100;
        uint256 amountToTransfer = amount - fee;

        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amountToTransfer;
        _balances[owner] = _balances[owner] + fee;

        emit Transfer(sender, recipient, amountToTransfer);
        if (fee > 0) {
            emit Transfer(sender, owner, fee);
        }
    }

    function _approve(address _owner, address spender, uint256 amount) internal {
        require(_owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
}