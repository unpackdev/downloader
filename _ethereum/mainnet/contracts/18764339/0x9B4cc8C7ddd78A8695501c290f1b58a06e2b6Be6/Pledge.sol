// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;
import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";


/**
 *   __ _ _ __   _____  ____      ____ _| |_ ___| |__   ___| |_   _| |__  
 *  / _` | '_ \ / _ \ \/ /\ \ /\ / / _` | __/ __| '_ \ / __| | | | | '_ \ 
 * | (_| | |_) |  __/>  <  \ V  V / (_| | || (__| | | | (__| | |_| | |_) |
 *  \__,_| .__/ \___/_/\_\  \_/\_/ \__,_|\__\___|_| |_|\___|_|\__,_|_.__/ 
 *       |_|                                                              
 *
 * @title Ownable USDT/USDC Pledge Contract
 *
 * @dev This contract is specifically built for Apex Watch Club Pledge
 */
contract Pledge is Ownable, ReentrancyGuard {
  // #############################
  // #         VARIABLES         #
  // #############################
  
  /**
   * @dev This mapping is used to determine how many a certain address pledged
   */
  mapping(address => uint256) _pledged;

	bool _isFrozen = true;
	uint256 _pledgePrice;
	uint256 _totalPledgedCount;
	uint256 _totalSupply;
	IERC20 _tokenUsdc;
	IERC20 _tokenUsdt;

  // #############################
  // #          EVENTS           #
  // #############################

	event PledgeUsdt(address _from, address _to, uint256 _amount, uint256 _timestamp);
	event PledgeUsdc(address _from, address _to, uint256 _amount, uint256 _timestamp);
	event WithdrawUsdt(address _to, uint256 _amount, uint256 _timestamp);
	event WithdrawUsdc(address _to, uint256 _amount, uint256 _timestamp);
	event Freeze(bool _status, uint256 _timestamp);
	event Unfreeze(bool _status, uint256 _timestamp);
	event PriceSet(uint256 _old, uint256 _new, uint256 _timestamp);
	event PledgedCountSet(uint256 _old, uint256 _new, uint256 _timestamp);
	event SupplySet(uint256 _old, uint256 _new, uint256 _timestamp);

	constructor(address _usdt, address _usdc, uint256 _supply, uint256 _price) Ownable(address(msg.sender)) ReentrancyGuard() {
		_tokenUsdt = IERC20(_usdt);
		_tokenUsdc = IERC20(_usdc);
		_pledgePrice = _price;
		_totalSupply = _supply; 
	}

  // #############################
  // #      PLEDGE FUNCTIONS     #
  // #############################

	function pledgeUsdt(uint256 _amount) public nonReentrant returns (bool) {
		// only admin can change state when frozen
		require(!_isFrozen || msg.sender == owner(), "All state changing transactions currently frozen.");
		// must be a multiple of _pledgePrice
		require(_amount % _pledgePrice == 0, 'Pledge amount must be a multiple of current price.');
		// must not exceed set supply
		uint256 _count = _amount / _pledgePrice;
		require(_totalPledgedCount + _count < _totalSupply, "Not enough supply. Consider reducing your pledge count.");
		// must have enough allowance
		require(_tokenUsdt.allowance(msg.sender, address(this)) >= _amount, 'USDT allowance not enough.');
		// must have enough USDT
		require(_amount <= _tokenUsdt.balanceOf(msg.sender), "Insufficient USDT balance.");

		_pledged[msg.sender] = _pledged[msg.sender] + _amount;
		_totalPledgedCount = _totalPledgedCount + _count;

		emit PledgeUsdt(msg.sender, address(this), _amount, block.timestamp);
		return  _tokenUsdt.transferFrom(msg.sender, address(this), _amount);
	}


	function pledgeUsdc(uint256 _amount) public nonReentrant returns (bool) {
		// only admin can change state when frozen
		require(!_isFrozen || msg.sender == owner(), "All state changing transactions currently frozen.");
		// must be a multiple of _pledgePrice
		require(_amount % _pledgePrice == 0, 'Pledge amount must be a multiple of current price.');
		// must not exceed set supply
		uint256 _count = _amount / _pledgePrice;
		require(_totalPledgedCount + _count < _totalSupply, "Not enough supply. Consider reducing your pledge count.");
		// must have enough allowance
		require(_tokenUsdc.allowance(msg.sender, address(this)) >= _amount, "USDC allowance not enough.");
		// must have enough USDC
		require(_amount <= _tokenUsdc.balanceOf(msg.sender), "Insufficient USDC balance.");

		_pledged[msg.sender] = _pledged[msg.sender] + _amount;
		_totalPledgedCount = _totalPledgedCount + _count;

		emit PledgeUsdc(msg.sender, address(this), _amount, block.timestamp);
		return _tokenUsdc.transferFrom(msg.sender, address(this), _amount);
	}

  // #############################
  // #       VIEW FUNCTIONS      #
  // #############################

	function getPledged(address _address) public view returns (uint256) {
		return _pledged[_address];
	}


	function getTotalPledgedCount() public view returns (uint256) {
		return _totalPledgedCount;
	}
	

	function getTotalSupply() public view returns (uint256) {
		return _totalSupply;
	}


	function getPrice() public view returns (uint256) {
		return _pledgePrice;
	}


  function getIsFrozen() public view returns (bool) {
    return _isFrozen;
  }


  // #############################
  // #      OWNER FUNCTIONS      #
  // #############################

	function setPrice(uint256 _newPrice) public onlyOwner returns (uint256) {
		// only admin can change state when frozen
		require(!_isFrozen || msg.sender == owner(), "All state changing transactions currently frozen.");
		require(_newPrice > 0, "New price must be greater than 0.");

		emit PriceSet(_pledgePrice, _newPrice, block.timestamp);

		_pledgePrice = _newPrice;
		return _pledgePrice;
	}

	function setTotalPledgedCount(uint256 _newTotalPledgedCount) public onlyOwner returns (uint256) {
		// only admin can change state when frozen
		require(!_isFrozen || msg.sender == owner(), "All state changing transactions currently frozen.");

		emit PledgedCountSet(_totalPledgedCount, _newTotalPledgedCount, block.timestamp);

		_totalPledgedCount = _newTotalPledgedCount;
		return _totalPledgedCount;
	}

	function setTotalSupply(uint256 _newSupply) public onlyOwner returns (uint256) {
		// only admin can change state when frozen
		require(!_isFrozen || msg.sender == owner(), "All state changing transactions currently frozen.");

		emit SupplySet(_totalSupply, _newSupply, block.timestamp);

		_totalSupply = _newSupply;
		return _totalSupply;
	}


  /**
   * @dev Prevent all non-admin transactions in case of emergency
   */
	function freeze() public onlyOwner {
		require(!_isFrozen, "Already frozen.");
		_isFrozen = true;
		emit Freeze(_isFrozen, block.timestamp);
	}
	

  /**
   * @dev Toggle opening / closing of pledging
   */
	function unfreeze() public onlyOwner {
		require(_isFrozen, "Not frozen.");
		_isFrozen = false;
		emit Unfreeze(_isFrozen, block.timestamp);
	}

	
	function withdrawUsdt() public onlyOwner nonReentrant returns (bool) {
		require(msg.sender == owner(), 'Only admin can withdraw USDT.');

		uint256 _amount = _tokenUsdt.balanceOf(address(this));

		emit WithdrawUsdt(msg.sender, _amount, block.timestamp);

		return _tokenUsdt.transfer(msg.sender, _amount);
	}


	function withdrawUsdc() public onlyOwner nonReentrant returns (bool) {
		require(msg.sender == owner(), 'Only admin can withdraw USDC.');

		uint256 _amount = _tokenUsdc.balanceOf(address(this));

		emit WithdrawUsdc(msg.sender, _amount, block.timestamp);

		return _tokenUsdc.transfer(msg.sender, _amount);
	}
}
