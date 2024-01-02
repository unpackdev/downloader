/*

The name "Killer Whales" were given to Orcas because ancient sailors saw them preying on large whales,
when in fact they are the largest species of dolphin.

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@/@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(@@@@.@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,@&@@&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@*((#%%&&&&&&&&%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@%%%%%%%&&&&&&@@@@@@@&&&&#**(%%%%%%#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@&@&*.(@@@@@@@&&&&&&&&&&&&&%%%%&&@@@@@@@@@@@&&&&@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@*(&#,    %@@@@@@@@@@@@@@@@@&&&&&&&&&@@@@@@@@@@@@@@@@@&&%@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@*.    .@&&@@@&&@@@@@@@@@@@@@@@@,      @@@@@@@@@@@@@@&&@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@#&&&&&&&&&,%@@@@@@%        .&@@@@@@@@@@@@@@&&@@@&/@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@#%&&@@&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/*@%*@@@@@@@%%%%#@@@@@
@@@@@@@@@@@@@@@@@@@@@@%&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&%%(@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


*/
// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


pragma solidity ^0.8.0;

interface IERC20Metadata is IERC20 {
    
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
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
 
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    }

pragma solidity ^0.8.0;

contract iWHALE is Context, IERC20, IERC20Metadata, Ownable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
    address private _feeRecipient;
    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor (string memory name_, string memory symbol_, uint256 totalSupply_, address feeRecipient_) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_;
         _feeRecipient = feeRecipient_;
        _balances[msg.sender] = totalSupply_;
        emit Transfer(address(0), msg.sender, totalSupply_); // Optional
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
    if (account == address(0)) {
        return 0;
    }
    return _balances[account];
    }

    function setFeeRecipient(address feeRecipient) public onlyOwner {
    require(feeRecipient != address(0), "Fee recipient cannot be the zero address");
    _feeRecipient = feeRecipient;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    address sender = _msgSender();
    require(sender != address(0), "ERC20: transfer from the zero address");

    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

    uint256 fee = amount / 100; // calculate 1% fee
    uint256 burnAmount = fee / 2; // calculate burn amount (half of fee)
    uint256 transferAmount = amount - fee; // calculate transfer amount (original amount minus fee)
    
    if (_feeRecipient != address(0)) {
        uint256 feeRecipientAmount = fee - burnAmount; // calculate the feeRecipient amount (other half of the fee)
        
        _balances[sender] -= amount; // subtract amount from sender's balance
        _balances[recipient] += transferAmount; // add transfer amount to recipient
        _balances[_feeRecipient] += feeRecipientAmount; // add the feeRecipient amount to feeRecipient's balance
        _balances[address(0)] += burnAmount; // add burn amount to the 0 address
        
        emit Transfer(sender, recipient, transferAmount); // emit transfer event to recipient
        emit Transfer(sender, _feeRecipient, feeRecipientAmount); // emit transfer event for feeRecipient amount
        emit Transfer(sender, address(0), burnAmount); // emit transfer event to burn address
        
        if (burnAmount > 0) {
            _totalSupply -= burnAmount; // update total supply by burning tokens
        }
    } else {
        // if feeRecipient address is not set/invalid, burn the fee instead
        _balances[sender] -= amount; // subtract amount from sender's balance
        _balances[recipient] += transferAmount; // add transfer amount to recipient
        _balances[address(0)] += fee; // add burn amount to the 0 address
        
        emit Transfer(sender, recipient, transferAmount); // emit transfer event to recipient
        emit Transfer(sender, address(0), fee); // emit transfer event to burn address
        
        _totalSupply -= fee; // update total supply by burning tokens
    }
    
    return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
    require(amount <= _allowances[sender][_msgSender()], "ERC20: transfer amount exceeds allowance");

    _allowances[sender][_msgSender()] -= amount;

    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

    uint256 fee = amount / 100;
    uint256 burnAmount = fee / 2;
    uint256 transferAmount = amount - fee;

    if (_feeRecipient != address(0)) {
        uint256 feeRecipientAmount = fee - burnAmount;

        _balances[sender] -= amount;
        _balances[recipient] += transferAmount;
        _balances[_feeRecipient] += feeRecipientAmount;
        _balances[address(0)] += burnAmount;

        emit Transfer(sender, recipient, transferAmount);
        emit Transfer(sender, _feeRecipient, feeRecipientAmount);
        emit Transfer(sender, address(0), burnAmount);

        if (burnAmount > 0) {
            _totalSupply -= burnAmount;
        }
    } else {
        _balances[sender] -= amount;
        _balances[recipient] += transferAmount;
        _balances[address(0)] += fee;

        emit Transfer(sender, recipient, transferAmount);
        emit Transfer(sender, address(0), fee);

        _totalSupply -= fee;
    }

    return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
    require(from != address(0), "ERC20: transfer from the zero address");
        
    _beforeTokenTransfer(from, to, amount);
        
    uint256 fromBalance = _balances[from];
    require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        _balances[from] = fromBalance - amount;
    }
        
    uint256 fee = amount / 100; // calculate 1% fee
    uint256 burnAmount = fee / 2; // calculate burn amount (half of fee)
    uint256 transferAmount = amount - fee; // calculate transfer amount (original amount minus fee)
    
    if (_feeRecipient != address(0)) {
        uint256 feeRecipientAmount = fee - burnAmount; // calculate the feeRecipient amount (other half of the fee)
        _balances[_feeRecipient] += feeRecipientAmount; // add the feeRecipient amount to feeRecipient's balance
        emit Transfer(from, _feeRecipient, feeRecipientAmount); // emit transfer event for feeRecipient amount
        if (burnAmount > 0) {
            _totalSupply -= burnAmount; // update total supply by burning tokens
            _balances[address(0)] += burnAmount; // add burn amount to the 0 address
            emit Transfer(from, address(0), burnAmount); // emit burn event
        }
    } else {
        // if feeRecipient address is not set/invalid, burn the fee instead
        _totalSupply -= fee; // update total supply by burning tokens
        _balances[address(0)] += fee; // add burn amount to the 0 address
        emit Transfer(from, address(0), fee); // emit burn event
    }
        
    _balances[to] += transferAmount; // add transfer amount to recipient
    emit Transfer(from, to, transferAmount); // emit transfer event
        
    _afterTokenTransfer(from, to, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}