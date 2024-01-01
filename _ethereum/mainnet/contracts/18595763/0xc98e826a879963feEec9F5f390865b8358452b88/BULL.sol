// SPDX-License-Identifier: MIT

/**
$BULL

*/


pragma solidity ^0.8.0;

contract BULL {
    string public name = "BULL";
    string public symbol = "BULL";
    uint8 public decimals = 18; // Assuming 18 decimals for most tokens
    uint256 public totalSupply = 999999999999 * 10**uint256(decimals);
    address public owner;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event LPLocked(address indexed account, uint256 amount);

    constructor() {
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "BULL");
        _;
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(_to != address(0), "BULLBULL");
        require(balanceOf[msg.sender] >= _value, "BULLBULLBULL");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        require(_from != address(0), "BULLBULLBULLBULL");
        require(_to != address(0), "BULLBULLBULLBULLBULL");
        require(balanceOf[_from] >= _value, "1BULL");
        require(allowance[_from][msg.sender] >= _value, "2BULL");

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    function renounceOwnership() external onlyOwner {
        owner = address(0);
    }

    function lockLPToken(uint256 amount) external {
        emit LPLocked(msg.sender, amount);
    }
}