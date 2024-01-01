// SPDX-License-Identifier: MIT

/** 

https://t.me/SAFEGROK
https://twitter.com/SAFEGROKeth
https://safegrok.xyz


    \_\
   (_**)
  __) #_
 ( )...()
 || | |I|
 || | |()__/
 /\(___)
_-"""""""-_""-_
-,,,,,,,,- ,,-

**/


pragma solidity ^0.8.17;

abstract contract Context
{
    function _msgSender() internal view virtual returns (address)
    {
        return msg.sender;
    }
}

interface IERC20
{
    function totalSupply() external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

library SafeMath
{
    function sub(uint256 a, uint256 b) internal pure returns (uint256)
    {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256)
    {
        if (a == 0)
        {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256)
    {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256)
    {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256)
    {
        return div(a, b, "SafeMath: division by zero");
    }
}

contract Ownable is Context
{
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor ()
    {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    modifier onlyOwner()
    {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner
    {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function owner() public view returns (address)
    {
        return _owner;
    }
}

contract SAFEGROK is Context, IERC20, Ownable
{
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private constant _totalSupply = 1_010_000_000_000 * 10**9;
    string private constant _name = "SAFEGROK";
    string private constant _symbol = "SAFEGROK";

    constructor ()
    {
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public pure returns (string memory)
    {
        return _name;
    }

    function symbol() public pure returns (string memory)
    {
        return _symbol;
    }

    function allowance(address owner, address spender) public view override returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function totalSupply() public pure override returns (uint256)
    {
        return _totalSupply;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function balanceOf(address account) public view override returns (uint256)
    {
        return _balances[account];
    }

    function approve(address spender, uint256 amount) public override returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function decimals() public pure returns (uint8)
    {
        return 9;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool)
    {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual
    {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(sender != address(0), "ERC20: transfer from the zero address");

        uint256 fromBalance = _balances[sender];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = fromBalance - amount;

        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) private
    {
        require(spender != address(0), "ERC20: approve to the zero address");
        require(owner != address(0), "ERC20: approve from the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}