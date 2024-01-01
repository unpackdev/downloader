// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.0;



contract Token {
    mapping (address => uint256) private _balances;
    address private _owner;
    
    mapping (address => mapping (address => uint256)) private _allowances;
    
    uint256 private _totalSupply = 1e9 * 10**18;
    
    
    uint tax = 0;
    
    string private _name = "MEO Coin";
    string private _symbol = "MEO";
    uint8 private _decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed spender, uint256 value);
    
    constructor ()  {        
        _owner = msg.sender;
        _mint(_owner, _totalSupply);

    }


    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        unchecked {_balances[account] += amount;}
        emit Transfer(address(0), account, amount);

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

    function totalSupply() public  view returns (uint256) {
        return _totalSupply;
    }



    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function owner() public view returns(address){
        return _owner;
    }

function handletransfer(address sender, address recipient, uint amount) internal returns(bool success) {
    require(_balances[sender] >= amount, "Insufficient Amount");
     
        uint256 feeTransfer = (amount * tax) / 100;
        uint256 amountAfterFee = amount - feeTransfer;
        
        _transfer(sender, recipient, amountAfterFee);
        _burn(sender, feeTransfer);
        return true;
}

    function transfer(address recipient, uint256 amount) public returns (bool success) {
      return handletransfer(msg.sender, recipient, amount);

    }


    function allowance(address sender, address spender) public  view returns (uint256) {
        return _allowances[sender][spender];
    }

    function approve(address spender, uint256 amount) public  returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function setTax(uint _tax) external returns(bool) {
        require(msg.sender == _owner, "Only _owner can set tax");
        tax = _tax;
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(amount <= _allowances[sender][msg.sender], "Transfer amount cannot exceeds allowance");
        _allowances[sender][msg.sender] -= amount;
        handletransfer(sender, recipient, amount);
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(subtractedValue >= _allowances[msg.sender][spender], "decreased allowance below zero");
        _allowances[msg.sender][spender] -= subtractedValue;

        return true;
    }


    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }
    

    function _approve(address sender, address spender, uint256 amount) internal {
        require(sender != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }


    function _burn(address account, uint256 amount) internal virtual {
        _balances[account] -= amount;
        unchecked {_totalSupply -= amount;}
        emit Transfer(account, address(0), amount);

    }
}