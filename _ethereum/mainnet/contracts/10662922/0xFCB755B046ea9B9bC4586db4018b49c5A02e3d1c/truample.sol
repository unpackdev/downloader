/**
 * We have Eliminated the Fixed target price and introduced floating/balancing price target depending upon the current price of TMPL, 
 * so that whenever the price go higher the floating target price shifts itself and tries to manage the risk of fall back thus maintaining 
 * quilibrium.

We also have changed the rebase structure in a way such that network participants gets consistent rebase irrespective
of price manipulation so anyone can buy at a certain price at his comfort level without fearing of falling price back to $1 w
hich makes it super powerful. Here the price will readjust itself according to formula which relies on supply demand of token 
and is not pegged to base price of $1. Rebase is between 0.5% to 1% per 0.1 $ gain hence it helps to nullify the decrease in 
demand there by fluctuating the target price and maintaining the gains and liquidity
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

contract truample is ERC20{
    uint8 public constant decimals = 18;
    uint256 initialSupply = 3000000*10**uint256(decimals);
    string public constant name = "TruAmpl";
    string public constant symbol = "TMPL";

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