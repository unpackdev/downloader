// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MouseWifHat {
    string public name = "MouseWifHat";
    string public symbol = "MOUSE";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100000000 * 10**uint256(decimals);
    uint256 public burnRate = 1; // 1% burn rate

    address public owner;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        uint256 burnAmount = _value * burnRate / 100;
        uint256 sendAmount = _value - burnAmount;
        require(_value == sendAmount + burnAmount, "Burn value invalid");

        balanceOf[_from] -= _value;
        balanceOf[_to] += sendAmount;
        if (burnAmount > 0) {
            totalSupply -= burnAmount;
            emit Transfer(_from, address(0), burnAmount);
        }
        emit Transfer(_from, _to, sendAmount);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender], "Allowance exceeded");
        require(_value <= balanceOf[_from], "Balance exceeded");
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
}