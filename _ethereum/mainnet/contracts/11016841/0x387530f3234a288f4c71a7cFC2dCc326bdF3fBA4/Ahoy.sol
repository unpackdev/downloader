pragma solidity ^0.5.17;

interface Callable {
	function tokenCallback(address _from, uint256 _tokens, bytes calldata _data) external returns (bool);
}

contract Ahoy {

	//CONTRACT PARAMS

	//Aggresive burning rate of 10 percent
	uint256 constant private BURNING_RATE = 10;

	//Total supply of 100 million
	uint256 constant private INITIAL_SUPPLY = 1e26;

	//Minimum supply of 5 percent
	//There will be no less than 5 million tokens
	uint256 constant private MINIMUM_SUPPLY_PERCENTAGE = 5;

	//Minimum stake amount
	uint256 constant private MIN_STAKE_AMOUNT = 1000;

	//Currency name
	string constant public name = "Ahoy";

	//Amount of decimals
	uint8 constant public decimals = 18;

	//Token symbol
	string constant public symbol = "AHY";

	//A default scalar value
	//This is used in various calculations throughout this contract
	uint256 constant private DEFAULT_SCALAR_VALUE = 2**64;

	//USER SECTION

	struct User {
		uint256 balance;
		uint256 staked;
		mapping(address => uint256) allowance;

		//payout is calculated with the default scalar value
		int256 scaledPayout;

		//certain addresses (eg. for swap pools) can have burning disabled, so users can safely exchange tokens without losing value
		//only the creator address is allowed to exclude addresses from burning
		bool burningDisabled;
	}


	//CONTRACT INFO


	struct Info {
		//An admin address will be used for certain functionalities
		address adminAddress;

		//Used to check contract details within the Ahoy wallet
		uint256 totalSupply;
		uint256 totalStaked;
		mapping(address => User) users;

		//Scaled payout per token
		//used to determine how much tokens a user gets
		uint256 scaledPayoutPerToken;
	}


	Info private info;


	//EVENTS SECTION


	event Stake(address indexed owner, uint256 tokens);
	event Unstake(address indexed owner, uint256 tokens);
	event Approval(address indexed owner, address indexed spender, uint256 tokens);
	event DisableBurning(address indexed user, bool status);
	event Collect(address indexed owner, uint256 tokens);
	event Burn(uint256 tokens);
	event Transfer(address indexed from, address indexed to, uint256 tokens);


	//CONTRACT CONSTRUCTOR


	constructor() public {
		info.adminAddress = msg.sender;
		info.totalSupply = INITIAL_SUPPLY;
		info.users[msg.sender].balance = INITIAL_SUPPLY;
		emit Transfer(address(0x0), msg.sender, INITIAL_SUPPLY);
		disableBurning(msg.sender, true);
	}


	//CONTRACT FUNCTIONS


	//TOKEN BURN
	function burn(uint256 _tokens) external {
		require(balanceOf(msg.sender) >= _tokens);
		info.users[msg.sender].balance -= _tokens;
		uint256 _burnedAmount = _tokens;

		//Calculate the staking reward
		if (info.totalStaked > 0) {
			_burnedAmount /= 2;
			info.scaledPayoutPerToken += _burnedAmount * DEFAULT_SCALAR_VALUE / info.totalStaked;
			emit Transfer(msg.sender, address(this), _burnedAmount);
		}

		info.totalSupply -= _burnedAmount;

		//EMIT TRANSFER AND BURN EVENTS
		emit Transfer(msg.sender, address(0x0), _burnedAmount);
		emit Burn(_burnedAmount);
	}


	//TOKEN STAKE
	function stake(uint256 _tokens) external {
		_stake(_tokens);
	}


	//TOKEN UNSTAKE
	function unstake(uint256 _tokens) external {
		_unstake(_tokens);
	}


	//APPROVE
	function approve(address _spender, uint256 _tokens) external returns (bool) {
		info.users[msg.sender].allowance[_spender] = _tokens;
		emit Approval(msg.sender, _spender, _tokens);
		return true;
	}


	//TRANSFERS


	//TRANSFER AND CALL
	function transferAndCall(address _to, uint256 _tokens, bytes calldata _data) external returns (bool) {
		uint256 _transferred = _transfer(msg.sender, _to, _tokens);
		uint32 _size;
		assembly {
			_size := extcodesize(_to)
		}
		if (_size > 0) {
			require(Callable(_to).tokenCallback(msg.sender, _transferred, _data));
		}
		return true;
	}


	//tokens are burned when transfering if burning is not disabled
	function _transfer(address _from, address _to, uint256 _tokens) internal returns (uint256) {
		require(balanceOf(_from) >= _tokens);
		info.users[_from].balance -= _tokens;
		uint256 _burnedAmount = _tokens * BURNING_RATE / 100;

		//Check if burned amount should be zero
		if (totalSupply() - _burnedAmount < INITIAL_SUPPLY * MINIMUM_SUPPLY_PERCENTAGE / 100 || isBurningDisabled(_from)) {
			_burnedAmount = 0;
		}

		//Update balance
		uint256 _transferred = _tokens - _burnedAmount;
		info.users[_to].balance += _transferred;

		//Make the transfer
		emit Transfer(_from, _to, _transferred);
		if (_burnedAmount > 0) {

			//update the scaled payout per token if totalStaked > 0
			if (info.totalStaked > 0) {
				_burnedAmount /= 2;
				info.scaledPayoutPerToken += _burnedAmount * DEFAULT_SCALAR_VALUE / info.totalStaked;
				emit Transfer(_from, address(this), _burnedAmount);
			}

			//update the total supply and emit the events
			info.totalSupply -= _burnedAmount;
			emit Transfer(_from, address(0x0), _burnedAmount);
			emit Burn(_burnedAmount);
		}

		//return the transferred amount (tokens - burnedAmount)
		return _transferred;
	}


	//BULK TRANSFER
	function bulkTransfer(address[] calldata _receivers, uint256[] calldata _amounts) external {
		require(_receivers.length == _amounts.length);
		for (uint256 i = 0; i < _receivers.length; i++) {
			_transfer(msg.sender, _receivers[i], _amounts[i]);
		}
	}

	//TRANSFER FROM
	function transferFrom(address _from, address _to, uint256 _tokens) external returns (bool) {
		//USE ALLOWANCE TO DETERMINE VALIDITY
		require(info.users[_from].allowance[msg.sender] >= _tokens);
		info.users[_from].allowance[msg.sender] -= _tokens;
		_transfer(_from, _to, _tokens);
		return true;
	}

	//REGULAR TRANSFER
	function transfer(address _to, uint256 _tokens) external returns (bool) {
		_transfer(msg.sender, _to, _tokens);
		return true;
	}


	//DISTRIBUTE TOKENS
	function distribute(uint256 _tokens) external {
		require(info.totalStaked > 0);
		require(balanceOf(msg.sender) >= _tokens);
		info.users[msg.sender].balance -= _tokens;
		info.scaledPayoutPerToken += _tokens * DEFAULT_SCALAR_VALUE / info.totalStaked;
		emit Transfer(msg.sender, address(this), _tokens);
	}


	//DISABLE BURNING FOR A CERTAIN ADDRESS
	//THIS CAN ONLY BE USED BY THE ADMIN
	function disableBurning(address _user, bool _status) public {
		require(msg.sender == info.adminAddress);
		info.users[_user].burningDisabled = _status;
		emit DisableBurning(_user, _status);
	}


	//INFO FUNCTIONS

	//GET TOTAL STAKED
	function totalStaked() public view returns (uint256) {
		return info.totalStaked;
	}

	//GET TOTAL SUPPLY
	function totalSupply() public view returns (uint256) {
		return info.totalSupply;
	}

	//GET DIVIDENDS OF
	function dividendsOf(address _user) public view returns (uint256) {
		return uint256(int256(info.scaledPayoutPerToken * info.users[_user].staked) - info.users[_user].scaledPayout) / DEFAULT_SCALAR_VALUE;
	}

	//GET ALLOWANCE
	function allowance(address _user, address _spender) public view returns (uint256) {
		return info.users[_user].allowance[_spender];
	}

	//GET BALANCE OF
	function balanceOf(address _user) public view returns (uint256) {
		return info.users[_user].balance - stakedOf(_user);
	}

	//GET STAKED OF
	function stakedOf(address _user) public view returns (uint256) {
		return info.users[_user].staked;
	}

	//CHECK IF BURNING IS DISABLED
	function isBurningDisabled(address _user) public view returns (bool) {
		return info.users[_user].burningDisabled;
	}

	//GET ALL THE INFO FOR A USER
	function infoFor(address _user) public view returns (uint256 totalTokenSupply, uint256 totalTokensStaked, uint256 userBalance, uint256 userStaked, uint256 userDividends) {
		return (totalSupply(), totalStaked(), balanceOf(_user), stakedOf(_user), dividendsOf(_user));
	}

	//STAKE TOKENS
	function _stake(uint256 _amount) internal {
		//Check balance and currently staked
		require(balanceOf(msg.sender) >= _amount);
		require(stakedOf(msg.sender) + _amount >= MIN_STAKE_AMOUNT);
		info.totalStaked += _amount;

		//Calculate the scaled payout
		info.users[msg.sender].staked += _amount;
		info.users[msg.sender].scaledPayout += int256(_amount * info.scaledPayoutPerToken);

		//Emit the events
		emit Transfer(msg.sender, address(this), _amount);
		emit Stake(msg.sender, _amount);
	}

	//users can collect dividends
	function collect() external returns (uint256) {
		uint256 _dividends = dividendsOf(msg.sender);
		require(_dividends >= 0);

		//Calculate the payout
		info.users[msg.sender].scaledPayout += int256(_dividends * DEFAULT_SCALAR_VALUE);
		info.users[msg.sender].balance += _dividends;

		//Emit the events
		emit Transfer(address(this), msg.sender, _dividends);
		emit Collect(msg.sender, _dividends);

		//Return the dividends
		return _dividends;
	}

	//UNSTAKE TOKENS
	//WHEN UNSTAKING, TOKENS ARE ALSO BURNED, INCREASING THE STAKING REWARDS FOR OTHERS
	function _unstake(uint256 _amount) internal {
		require(stakedOf(msg.sender) >= _amount);
		uint256 _burnedAmount = _amount * BURNING_RATE / 100;

		//update the scaled payout per token
		info.scaledPayoutPerToken += _burnedAmount * DEFAULT_SCALAR_VALUE / info.totalStaked;

		info.totalStaked -= _amount;
		info.users[msg.sender].balance -= _burnedAmount;
		info.users[msg.sender].staked -= _amount;
		info.users[msg.sender].scaledPayout -= int256(_amount * info.scaledPayoutPerToken);

		//Emit the events
		emit Transfer(address(this), msg.sender, _amount - _burnedAmount);
		emit Unstake(msg.sender, _amount);
	}


}