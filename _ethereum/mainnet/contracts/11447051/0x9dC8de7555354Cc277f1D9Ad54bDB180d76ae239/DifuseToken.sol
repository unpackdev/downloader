// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

import "./SafeMath.sol";

contract DifuseToken {
    using SafeMath for uint256;

    string public name = "DifuseToken";
    string public symbol = "DFUSE";
    uint8 public decimals = 18;

    uint256 public totalSupply;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(uint256 _initialSupply) {
        balanceOf[msg.sender] = _initialSupply.mul((uint256(10)**decimals));
        totalSupply = _initialSupply.mul((uint256(10)**decimals));
    }

    function transfer(address _to, uint256 _value)
        external
        returns (bool success)
    {
        require(_to != address(0), "Zero addresses not allowed");
        require(
            balanceOf[msg.sender] >= _value,
            "Not enough money to transfer"
        );

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
        external
        returns (bool success)
    {
        require(_spender != address(0), "Zero addresses not allowed");

        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success) {
        require(_to != address(0), "Zero addresses not allowed");
        require(
            _value <= balanceOf[_from],
            "Not enough money to transfer from"
        );
        require(
            _value <= allowance[_from][msg.sender],
            "Not enough money to transfer from"
        );

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) external returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Not enough money to burn");
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        return true;
    }

    function burnFrom(address _from, uint256 _value)
        external
        returns (bool success)
    {
        require(balanceOf[_from] >= _value, "Not enough money to burn");
        require(
            _value <= allowance[_from][msg.sender],
            "Not enough money to burn"
        );

        balanceOf[_from] = balanceOf[_from].sub(_value);
        totalSupply = totalSupply.sub(_value);
        return true;
    }
}
