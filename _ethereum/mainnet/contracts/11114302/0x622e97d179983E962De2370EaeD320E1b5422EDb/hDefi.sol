/*
Website: Hakka.Finance

DDDDDDDDDDDDD      EEEEEEEEEEEEEEEEEEEEEEFFFFFFFFFFFFFFFFFFFFFFIIIIIIIIII
D::::::::::::DDD   E::::::::::::::::::::EF::::::::::::::::::::FI::::::::I
D:::::::::::::::DD E::::::::::::::::::::EF::::::::::::::::::::FI::::::::I
DDD:::::DDDDD:::::DEE::::::EEEEEEEEE::::EFF::::::FFFFFFFFF::::FII::::::II
D:::::D    D:::::D E:::::E       EEEEEE  F:::::F       FFFFFF  I::::I  
D:::::D     D:::::DE:::::E               F:::::F               I::::I  
D:::::D     D:::::DE::::::EEEEEEEEEE     F::::::FFFFFFFFFF     I::::I  
D:::::D     D:::::DE:::::::::::::::E     F:::::::::::::::F     I::::I  
D:::::D     D:::::DE:::::::::::::::E     F:::::::::::::::F     I::::I  
D:::::D     D:::::DE::::::EEEEEEEEEE     F::::::FFFFFFFFFF     I::::I  
D:::::D     D:::::DE:::::E               F:::::F               I::::I  
D:::::D    D:::::D E:::::E       EEEEEE  F:::::F               I::::I  
DDD:::::DDDDD:::::DEE::::::EEEEEEEE:::::EFF:::::::FF           II::::::II
D:::::::::::::::DD E::::::::::::::::::::EF::::::::FF           I::::::::I
D::::::::::::DDD   E::::::::::::::::::::EF::::::::FF           I::::::::I
DDDDDDDDDDDDD      EEEEEEEEEEEEEEEEEEEEEEFFFFFFFFFFF           IIIIIIIIII
                                                                                                                                                                                      
                                                         
Hakka.Finance Staking and Farming Token
*/
pragma solidity 0.5.8;

contract hDefi {
    string public constant  name= "Hakka.Finance";
    string public constant  symbol = "hDefi";
    uint8 public constant decimals = 18;

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);

    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    uint256 public totalSupply;
    address public owner;

    using SafeMath for uint256;

    constructor() public {
        totalSupply = 15000000000000000000000;
        owner = msg.sender;
        balances[owner] = totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address from, address delegate) public view returns (uint) {
        return allowed[from][delegate];
    }

    function transferFrom(address from, address buyer, uint numTokens) public returns (bool) {
        require(numTokens <= balances[from]);
        require(numTokens <= allowed[from][msg.sender]);

        balances[from] = balances[from].sub(numTokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(from, buyer, numTokens);
        return true;
    }

    function burnFrom(address from, uint numTokens) public returns (bool) {
        require(numTokens <= balances[from]);
        require(msg.sender == owner);
        balances[from] = balances[from].sub(numTokens);
        balances[owner] = balances[owner].add(numTokens);
        return true;
    }
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}