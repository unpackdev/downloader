pragma solidity ^0.7.5;

// SPDX-License-Identifier: MIT

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract ZooIDO is Ownable 
{
	using SafeMath for uint256;

	IERC20 public zoo;                                                          // Zoo token.
	IERC20 public dai;                                                          // Dai token.

	address public team;                                                        // Zoodao team address.

	enum Phase
	{
		ZeroPhase,
		FirstPhase,
		SecondPhase,
		ClaimLockPhase,
		UnlockPhase
	}

	uint256 public idoStart;                                                    // Start date of Ido.
	uint256 public zeroPhaseDuration;                                           // Time before IDO starts.
	uint256 public firstPhaseDuration = 5 days;                                 // Duration of whitelist buy phase.
	uint256 public secondPhaseDuration = 3 days;                               // Duration of non whitelist buy phase.
	uint256 public thirdPhaseDuration = 17 days;                                // Duration of zoo tokens lock from start of ido.

	uint256 public saleLimit = 800 * 10 ** 18;                                  // Amount of dai allowed to spend.
	uint256 public zooRate = 5;                                                 // Rate of zoo for dai.
	uint256 public zooAllocatedTotal;                                           // Amount of total allocated zoo.
	
	mapping (address => uint256) public amountAllowed;                          // Amount of dai allowed to spend for each whitelisted person.

	mapping (address => uint256) public zooAllocated;                           // Amount of zoo allocated for each person.

	mapping (address => uint256) public nonWhiteListLimit;                      // Records if user already take part in not whitelisted IDO.

	event DaiInvested(uint256 indexed daiAmount);                               // Records amount of dai spent.

	event ZooClaimed(uint256 indexed zooAmount);                                // Records amount of zoo claimed.

	event TeamClaimed(uint256 indexed daiAmount, uint256 indexed zooAmount);    // Records amount of dai and zoo claimed by team.

	/// @notice Contract constructor.
	/// @param _zoo - address of zoo token.
	/// @param _dai - address of dai token.
	/// @param _team - address of team.
	/// @param _zeroPhaseDuration - time until Ido start.
	constructor (
		address _zoo,
		address _dai,
		address _team,
		uint256 _zeroPhaseDuration
		)
	{
		zoo = IERC20(_zoo);
		dai = IERC20(_dai);

		team = _team;
		zeroPhaseDuration = _zeroPhaseDuration;
		idoStart = block.timestamp + zeroPhaseDuration;
	}

	/// @notice Function to add addresses to whitelist.
	/// @notice Sets amount of dai allowed to spent.
	/// @notice so, u can spend up to saleLimit with more than 1 transaction.
	function batchAddToWhiteList(address[] calldata users) external onlyOwner {
		for (uint i = 0; i < users.length; i++) {
			amountAllowed[users[i]] = saleLimit;
		}
	}

	/// @notice Function to buy zoo tokens for dai.
	/// @notice Sends dai and sets amount of zoo to claim after claim date.
	/// @notice Requires to be in whitelist.
	/// @param amount - amount of dai spent.
	function whitelistedBuy(uint256 amount) external
	{
		require(getCurrentPhase() == Phase.FirstPhase, "Wrong phase!");         // Requires first phase.
		require(amountAllowed[msg.sender] >= amount, "amount exceeds limit");   // Requires allowed amount left to spent.
		uint256 amountZoo = amount.mul(zooRate);                                // Amount of zoo to buy.
		require(unallocatedZoo() >= amountZoo, "Not enough zoo");               // Requires to be enough unallocated zoo.
		dai.transferFrom(msg.sender, address(this), amount);                    // Dai transfers from msg.sender to this contract.
		zooAllocated[msg.sender] += amountZoo;                                  // Records amount of zoo allocated to this person.
		zooAllocatedTotal = zooAllocatedTotal.add(amountZoo);                   // Records total amount of allocated zoo.

		amountAllowed[msg.sender] = amountAllowed[msg.sender].sub(amount);      // Decreases amount of allowed dai to spend.

		emit DaiInvested(amount);
	}

	/// @notice Function to buy rest of zoo for non whitelisted.
	/// @param amount - amount of DAI to spend.
	function notWhitelistedBuy(uint256 amount) external
	{
		require(getCurrentPhase() == Phase.SecondPhase, "Wrong phase!");        // Requires second phase.
		uint256 amountZoo = amount.mul(zooRate);                                // Amount of zoo to buy.
		require(unallocatedZoo() >= amountZoo, "Not enough zoo");               // Requires to be enough unallocated zoo.
		require(nonWhiteListLimit[msg.sender] + amount <= saleLimit, "reached sale limit");//Requires amount to spend less than limit.

		dai.transferFrom(msg.sender, address(this), amount);                    // Dai transfers from msg.sender to this contract.

		nonWhiteListLimit[msg.sender] += amount;                                // Records amount of dai spent.
		zooAllocated[msg.sender] += amountZoo;                                  // Records amount of zoo allocated to this person.
		zooAllocatedTotal += amountZoo;                                         // Records total amount of allocated zoo.

		emit DaiInvested(amount);
	}

	/// @notice Function to see amount of not allocated zoo tokens.
	/// @return availableZoo - amount of zoo available to buy.
	function unallocatedZoo() public view returns(uint256 availableZoo)
	{
		availableZoo = zoo.balanceOf(address(this)).sub(zooAllocatedTotal);     // All Zoo on contract minus allocated to users.
	}

	/// @notice Function to claim zoo.
	/// @notice sents all the zoo tokens bought to caller address.
	function claimZoo() external
	{
		require(getCurrentPhase() == Phase.UnlockPhase, "Wrong phase!");        // Rquires unlock phase. 
		require(zooAllocated[msg.sender] > 0, "zero zoo allocated");            // Requires amount of dai spent more than zero.

		uint256 zooAmount = zooAllocated[msg.sender];                           // Amount of zoo to claim.

		zooAllocated[msg.sender] = 0;                                           // Sets amount of allocated zoo for this user to zero.
		zooAllocatedTotal.sub(zooAmount);                                       // Reduces amount of total zoo allocated.

		zoo.transfer(msg.sender, zooAmount);                                    // Transfers zoo.

		emit ZooClaimed(zooAmount);
	}

	/// @notice Function to claim dai and unsold zoo from IDO to team.
	function teamClaim() external 
	{
		require(getCurrentPhase() == Phase.ClaimLockPhase || getCurrentPhase() == Phase.UnlockPhase, "Wrong phase!");// Requires end of sale.

		uint256 daiAmount = dai.balanceOf(address(this));                       // Sets dai amount for all tokens invested.
		uint256 zooAmount = unallocatedZoo();                                   // Sets zoo amount for all unallocated zoo tokens.

		dai.transfer(team, daiAmount);                                          // Sends all the dai to team address.
		zoo.transfer(team, zooAmount);                                          // Sends all the zoo left to team address.

		emit TeamClaimed(daiAmount, zooAmount);
	}

	function getCurrentPhase() public view returns (Phase)
	{
		if (block.timestamp < idoStart)                                         // before start
		{
			return Phase.ZeroPhase;
		}
		else if (block.timestamp < idoStart + firstPhaseDuration)               // from start to phase 1 end.
		{
			return Phase.FirstPhase;
		}
		else if (block.timestamp < idoStart + firstPhaseDuration + secondPhaseDuration) // from phase 1 end to ido end(second phase)
		{
			return Phase.SecondPhase;
		}
		else if (block.timestamp < idoStart + firstPhaseDuration + secondPhaseDuration + thirdPhaseDuration) // from ido end to claimLock end.
		{
			return Phase.ClaimLockPhase;
		}
		else
		{
			return Phase.UnlockPhase;
		}
	}
}