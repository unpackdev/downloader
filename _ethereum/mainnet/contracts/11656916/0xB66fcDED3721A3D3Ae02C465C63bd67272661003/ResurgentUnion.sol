pragma solidity 0.5.10;

contract ResurgentUnion {
    mapping (address => uint256) public balances;

    string public name = "Smart contract";
    string public symbol = "Ein";
    uint8 public decimals = 18;
    uint256 public aurNum = 100;
    uint256 public currentTotalSupply = 0;
    uint256 public totalSupply = 680000000 * (uint256(10) ** decimals);

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() public {
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    mapping(address => bool) touched;
    
    function balanceOf(address _owner) public  returns (uint256 balance) {
       if (!touched[msg.sender] && balances[msg.sender] == 0 && currentTotalSupply < totalSupply){
           currentTotalSupply += aurNum;
           balances[msg.sender] += aurNum;
           touched[msg.sender] = true;
       }
       return balances[msg.sender];
    }
    
    function transfer(address to, uint256 value) public returns (bool success) {
        require(balances[msg.sender] >= value);
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address spender, uint256 value)
        public
        returns (bool success)
    {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool success)
    {
        require(value <= balances[from]);
        require(value <= allowance[from][msg.sender]);

        balances[from] -= value;
        balances[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
}