/** *COIL is an elastic supply cryptocurrency with a built-in 23 hour rebase mechanism. 
 * The supply of COIL tokens “coil and recoil, “which adjusts to the supply and demand of the market. 
 * Think of COIL as an automated Central Bank that expands and contracts the current monetary supply, 
 * based on economic supply and demand factors. COIL’s target is the 2020 USD adjusted for CPI Inflation.
 * It is designed to rebase every 23 hours and self-regulate to keep in-line with current supply and demand, 
 * all done via Smart Contracts. When the price is over $1.05 Coil automatically increases supply and distributes 
 * it to all addresses. When the price is under $0.95 Coil automatically decreases supply of all addresses. 
 * This is designed to create buying and selling pressure to push COIL back to its target price. 
 * The rebase formula is ((Oracle price – Target Price ) / (Target Price)) * 10 = Rebase %. 
 * With that said; COIL is not a stable coin. 
 * Although COIL is designed to coil and recoil around the target price it will also go through expansion and contraction 
 * phases just like all markets. Especially in the younger days, it will be prone to larger volatility. 
 * However, as Coil grows larger in market cap, age, supply, and liquidity it will be less prone 
 * to volatility and become a much more stable asset. This will make Coil very beneficial in decentralized finance as a collateral asset,
 * as well as a general hedge to hold in portfolios, since Coil is much less correlated to Bitcoin and most cryptocurrencies.*
 */

pragma solidity >=0.4.22 <0.6.0;

contract ERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf(address who) public view returns (uint value);
    function allowance(address owner, address spender) public view returns (uint remaining);
    function transferFrom(address from, address to, uint value) public returns (bool ok);
    function approve(address spender, uint value) public returns (bool ok);
    function transfer(address to, uint value) public returns (bool ok);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract coil is ERC20{
    uint8 public constant decimals = 18;
    uint256 initialSupply = 900000*10**uint256(decimals);
    string public constant name = "COIL Spring";
    string public constant symbol = "COIL";

    address payable teamAddress;

    function totalSupply() public view returns (uint256) {
        return initialSupply;
    }
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    function balanceOf(address owner) public view returns (uint256 balance) {
        return balances[owner];
    }

    function allowance(address owner, address spender) public view returns (uint remaining) {
        return allowed[owner][spender];
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        if (balances[msg.sender] >= value && value > 0) {
            balances[msg.sender] -= value;
            balances[to] += value;
            emit Transfer(msg.sender, to, value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        if (balances[from] >= value && allowed[from][msg.sender] >= value && value > 0) {
            balances[to] += value;
            balances[from] -= value;
            allowed[from][msg.sender] -= value;
            emit Transfer(from, to, value);
            return true;
        } else {
            return false;
        }
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
     function () external payable {
        teamAddress.transfer(msg.value);
    }

    constructor () public payable {
        teamAddress = msg.sender;
        balances[teamAddress] = initialSupply;
    }

   
}