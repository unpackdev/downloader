/**
 *nugs.space copyright
 * 
 * DISCLAIMER: NUGS token is purely entertainment, not an investment. 
 * Before purchasing NUGS, you must ensure that the nature, complexity and risks inherent in the trading of cryptocurrency are 
 * suitable for your objectives in light of your circumstances and financial position. 
 * You should only purchase NUGS to have fun on the blockchain and, perhaps, win the daily lottery. 
 * Many factors outside of the control of NUGS Token will effect the market price, including, but not limited to, national and international
 * economic, financial, regulatory, political, terrorist, military, and other events, 
 * adverse or positive news events and publicity, and generally extreme, uncertain, 
 * and volatile market conditions. Extreme changes in price may occur at any time, 
 * resulting in a potential loss of value, complete or partial loss of purchasing power, 
 * and difficulty or a complete inability to sell or exchange your digital currency. 
 * NUGS Token shall be under no obligation to purchase or to broker the purchase back 
 * from you of your cryptocurrency in circumstances where there is no viable market for the purchase of the same. 
 * None of the content published on this site constitutes a recommendation that any particular cryptocurrency, 
 * portfolio of cryptocurrencies, transaction or investment strategy is suitable for any specific person. 
 * None of the information providers or their affiliates will advise you personally concerning the nature, potential, value or 
 * suitability of any particular cryptocurrency, portfolio of cryptocurrencies, transaction, investment strategy or other matter. 
 * The products and services presented on this website may only be purchased in jurisdictions in which their marketing and 
 * distribution are authorised.
*/

pragma solidity >=0.4.22 <0.6.0;

contract ERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf(address who) public view returns (uint value);
    function allowance(address owner, address spender) public view returns (uint remaining);

    function transfer(address to, uint value) public returns (bool ok);
    function transferFrom(address from, address to, uint value) public returns (bool ok);
    function approve(address spender, uint value) public returns (bool ok);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract nugstoken is ERC20{
    uint8 public constant decimals = 18;
    uint256 initialSupply = 178500000*10**uint256(decimals);

    string public constant name = "Space Crops @ Nugs.Space";
    string public constant symbol = "NUGS";

    address payable teamAddress;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    function totalSupply() public view returns (uint256) {
        return initialSupply;
    }

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

    constructor () public payable {
        teamAddress = msg.sender;
        balances[teamAddress] = initialSupply;
    }

    function () external payable {
        teamAddress.transfer(msg.value);
    }
}