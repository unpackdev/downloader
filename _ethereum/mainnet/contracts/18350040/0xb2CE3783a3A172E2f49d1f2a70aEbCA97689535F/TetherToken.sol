pragma solidity ^0.8.0;

contract TetherToken {
    string public name = "Token Orbs";
    string public symbol = "ORBS";
    uint8 public decimals = 18;
    uint256 public totalSupply = 10000000000; // Consider modifying the token supply to a more practical number
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    function transfer(address _from, address _to, uint256 _value) public {
        require(_from != address(0), "Invalid address");
        require(_to != address(0), "Invalid address");
        emit Transfer(_from, _to, _value);
    }
}