pragma solidity ^0.6.0;

import "./SafeMath.sol";

contract TetherMock {
	using SafeMath for uint;

	string public name;
	string public symbol;
	uint public decimals;

	uint public _totalSupply;

	uint constant MAX_UINT = 2**256 - 1;
	mapping (address => mapping (address => uint)) allowed;
	mapping(address => uint) balances;

	// additional variables for use if transaction fees ever became necessary
	uint public basisPointsRate = 0;
	uint public maximumFee = 0;

	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);

	// Called when new token are issued
	event Issue(uint amount);

	// Called when tokens are redeemed
	event Redeem(uint amount);

	// Called when contract is deprecated
	event Deprecate(address newAddress);

	// Called if contract ever adds fees
	event Params(uint feeBasisPoints, uint maxFee);

	//  The contract can be initialized with a number of tokens
	//  All the tokens are deposited to the owner address
	//
	// @param _balance Initial supply of the contract
	// @param _name Token Name
	// @param _symbol Token symbol
	// @param _decimals Token decimals
	constructor(uint _initialSupply) public {
		_totalSupply = _initialSupply;
		balances[msg.sender] = balances[msg.sender].add(_initialSupply);
		name = 'USDT';
		symbol = 'USDT';
		decimals = 6;
	}

	function transferFrom(address _from, address _to, uint _value) public {
		uint256 _allowance = allowed[_from][msg.sender];

		// Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
		// if (_value > _allowance) throw;

		uint fee = (_value.mul(basisPointsRate)).div(10000);
		if (fee > maximumFee) {
			fee = maximumFee;
		}
		uint sendAmount = _value.sub(fee);

		balances[_to] = balances[_to].add(sendAmount);
		balances[_from] = balances[_from].sub(_value);
		if (_allowance < MAX_UINT) {
			allowed[_from][msg.sender] = _allowance.sub(_value);
		}
		Transfer(_from, _to, sendAmount);
	}

	/**
	 * @dev Gets the balance of the specified address.
	* @param _owner The address to query the the balance of.
	* @return balance An uint representing the amount owned by the passed address.
		*/
	function balanceOf(address _owner) view public returns (uint balance) {
		return balances[_owner];
	}

	/**
	* @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
	* @param _spender The address which will spend the funds.
	* @param _value The amount of tokens to be spent.
	*/
	function approve(address _spender, uint _value) public {

		// To change the approve amount you first have to reduce the addresses`
		//  allowance to zero by calling `approve(_spender, 0)` if it is not
		//  already 0 to mitigate the race condition described here:
		//  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
		require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));

		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
	}

	/**
	 * @dev Function to check the amount of tokens than an owner allowed to a spender.
	* @param _owner address The address which owns the funds.
		* @param _spender address The address which will spend the funds.
		* @return remaining A uint specifying the amount of tokens still available for the spender.
		*/
	function allowance(address _owner, address _spender) view public returns (uint remaining) {
		return allowed[_owner][_spender];
	}

	// deprecate current contract if favour of a new one
	function totalSupply() view public returns (uint){
		return _totalSupply;
	}

	/**
	* @dev transfer token for a specified address
	* @param _to The address to transfer to.
		* @param _value The amount to be transferred.
			*/
	function transfer(address _to, uint _value) public {
		uint fee = (_value.mul(basisPointsRate)).div(10000);
		if (fee > maximumFee) {
			fee = maximumFee;
		}
		uint sendAmount = _value.sub(fee);
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(sendAmount);
		Transfer(msg.sender, _to, sendAmount);
	}

	// Issue a new amount of tokens
	// these tokens are deposited into the owner address
	//
	// @param _amount Number of tokens to be issued
	function issue(address _to, uint amount) public {
		balances[_to] += amount;
		_totalSupply += amount;
		Issue(amount);
	}

	// Redeem tokens.
	// These tokens are withdrawn from the owner address
	// if the balance must be enough to cover the redeem
	// or the call will fail.
	// @param _amount Number of tokens to be issued
	function redeem(address _from, uint amount) public {
		require(_totalSupply >= amount);

		_totalSupply -= amount;
		balances[_from] -= amount;
		Redeem(amount);
	}
}
