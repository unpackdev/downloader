pragma solidity ^0.5.0;

import "./SafeMath.sol";

contract Token {
	using SafeMath for uint;

    // Variables
    string public name = "MicroLoanCoin";
    string public symbol = "MLc";
    uint256 public decimals = 18;
    uint256 public totalSupply;

    //Track balances
    mapping(address => uint256) public balanceOf;//transfer balance
    mapping(address => mapping(address => uint256)) public allowance; //nested mapping 1st key address of deployer, 
    //2nd key address of the specific exchange.

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    //Send tokens

    constructor() public {
        totalSupply = 1000000 * (10 ** decimals); //24 zeros
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

    //Approve tokens
    function approve(address _spender, uint256 _value) public returns (bool success) {
    	require(_spender != address(0));
    	allowance[msg.sender][_spender] = _value;
    	emit Approval(msg.sender, _spender, _value);
    	return true;
    }
   //Transfer from 
   function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

//END    
}