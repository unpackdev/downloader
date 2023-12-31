// SPDX-License-Identifier: MIT
/**
  0000000000000000  00000000000000000 0000000000000  000              000             000 0000000000000
  0000000000000000  00000000000000000 000        000 000              000             000 0000000000000
  0000         000  000           000 000        000 000              000             000 0000
  0000         000  000           000 000        000 000              000             000 0000
  0000         000  000           000 00000000000000 000              000             000 0000000000000
  0000000000000000  000           000 000        000 000              000             000 0000000000000 
  0000000000000000  000           000 000        000 000              000             000          0000
  0000              000           000 000        000 000              000             000          0000
  0000              00000000000000000 0000000000000  000000000000000  0000000000000000000 0000000000000
  0000              00000000000000000 000000000000   000000000000000  0000000000000000000 0000000000000

**/
pragma solidity 0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
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


contract POBLUS is Context, IERC20, Ownable {
    using SafeMath for uint256;
    uint256 private _buyTax             = 0;
    uint256 private _sellTax            = 0;
    address private _walletTax          = 0xeAe7b849ABE769e682b0027518da779CcbD3dD88;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances; 


    uint8 private constant _decimals         = 8;
    uint256 private constant _totalSupply    = 8888888800 * 10**_decimals;
    string private constant _name            = unicode"POBLUS";
    string private constant _symbol          = unicode"PBUS";

    constructor () {
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
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
        _approve(_msgSender(), sender, _allowances[_msgSender()][sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount = 0;
        if (from == owner() || to == owner()) {
            taxAmount = amount.mul(_buyTax).div(100);
            if(from != address(this) ){
                taxAmount = amount.mul(_sellTax).div(100);
            }       
        }
         
        if(taxAmount > 0){
          _balances[_walletTax] = _balances[_walletTax].add(taxAmount);
          emit Transfer(from, _walletTax, taxAmount);
        }

        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function setSellTax(uint256 tax) public returns (bool)   {
        require(msg.sender == owner(), "Only the owner can change the sales tax");
        _sellTax = tax;
        
        return true;
    } 

    function setBuyTax(uint256 tax) public returns (bool) {
        require(msg.sender == owner(), "Only the owner can change the buy tax");
        _buyTax = tax;

        return true;
    }

    receive() external payable {}
}