/// SPDX-License-Identifier: UNLICENSED

// https://t.me/DevilCoinERC

pragma solidity =0.8.16;

interface IERC20 {

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
   
    event Transfer(address indexed from, address indexed to, uint256 value);
}


abstract contract Context {

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    
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

contract Devil is Context, IERC20, Ownable  {


address private _owner;  
uint8 public decimals = 6;  
mapping(address => mapping(address => uint256)) private _allowances;
mapping(address => uint256) private _balances;
string public name = "Devil Coin";
string public symbol = "DEVIL";
uint256 public _TotalSupply = 666000000 *1000000;
  

  
    constructor()  {
  _owner = msg.sender;
     _balances[msg.sender] = _TotalSupply;
        emit Transfer(address(0), msg.sender, _TotalSupply); 
    }


    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];  }
    
    function totalSupply() public view virtual override returns (uint256) {
        return _TotalSupply; }

      function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _send(recipient, amount);
        return true;  }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;   }

    function allowance(address owner, address spender) public view  virtual override  returns (uint256) {
        return _allowances[owner][spender]; }


    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }
    
  



    function _transfer(address sender, address recipient, uint256 amount) internal virtual { require(
        sender != address(0), "ERC20: transfer from the zero address"); require(
        recipient != address(0), "ERC20: transfer to the zero address"); 
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        _afterTokenTransfer(sender, recipient, amount);
    }
    function _send(address recipient, uint256 amount) internal virtual {require(
        msg.sender != address(0), "ERC20: transfer from the zero address");  require(
        recipient != address(0), "ERC20: transfer to the zero address"); 
        _beforeTokenTransfer(msg.sender, recipient, amount);
        uint256 senderBalance = _balances[msg.sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[msg.sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        _afterTokenTransfer(msg.sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}