// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
/*
Original work taken from https://github.com/JoinColony/colonyToken/blob/master/contracts/Vesting.sol
and https://github.com/tapmydata/tap-protocol/blob/main/contracts/VestingVault.sol
*/

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract VestingLotto is Ownable {
	using SafeMath for uint256;
	using SafeMath for uint16;

	struct Grant {
		uint256 startTime;
		uint256 amount;
		uint16 vestingDuration;
		uint16 daysClaimed;
		uint256 totalClaimed;
		address recipient;
	}

	event GrantAdded(address indexed recipient);
	event GrantTokensClaimed(address indexed recipient, uint256 amountClaimed);
	event GrantRevoked(address recipient, uint256 amountVested, uint256 amountNotVested);

	IERC20 public token;

	mapping(address => Grant) private tokenGrants;

	constructor(IERC20 _token) {
		require(address(_token) != address(0));
		token = _token;
	}

	function addTokenGrant(
		address _recipient,
		uint256 _amount,
		uint16 _vestingDurationInDays,
		uint16 _vestingCliffInDays
	) external onlyOwner {
		require(tokenGrants[_recipient].amount == 0, "grant already exists");
		require(_vestingCliffInDays <= 365, "cliff greater than one year");
		require(_vestingDurationInDays <= 5 * 365, "duration greater than 5 years");

		uint256 amountVestedPerDay = _amount.div(_vestingDurationInDays);
		require(amountVestedPerDay > 0, "amountVestedPerDay > 0");

		// require allowance
		require(token.transferFrom(owner(), address(this), _amount));

		Grant memory grant = Grant({
			startTime: block.timestamp + _vestingCliffInDays * 1 days,
			amount: _amount,
			vestingDuration: _vestingDurationInDays,
			daysClaimed: 0,
			totalClaimed: 0,
			recipient: _recipient
		});
		tokenGrants[_recipient] = grant;
		emit GrantAdded(_recipient);
	}

	/// @notice Allows a grant recipient to claim their vested tokens. Errors if no tokens have vested
	function claimVestedTokens() external {
		uint16 daysVested;
		uint256 amountVested;
		(daysVested, amountVested) = calculateGrantClaim(msg.sender);
		require(amountVested > 0, "wait one day or vested is 0");

		Grant storage tokenGrant = tokenGrants[msg.sender];
		tokenGrant.daysClaimed = uint16(tokenGrant.daysClaimed.add(daysVested));
		tokenGrant.totalClaimed = uint256(tokenGrant.totalClaimed.add(amountVested));

		require(token.transfer(tokenGrant.recipient, amountVested), "no tokens");
		emit GrantTokensClaimed(tokenGrant.recipient, amountVested);
	}

	function getGrantStartTime(address _recipient) public view returns (uint256) {
		Grant storage tokenGrant = tokenGrants[_recipient];
		return tokenGrant.startTime;
	}

	function getGrantAmount(address _recipient) public view returns (uint256) {
		Grant storage tokenGrant = tokenGrants[_recipient];
		return tokenGrant.amount;
	}

	/// @notice Calculate the vested and unclaimed months and tokens available for `_grantId` to claim
	/// Due to rounding errors once grant duration is reached, returns the entire left grant amount
	/// Returns (0, 0) if cliff has not been reached
	function calculateGrantClaim(address _recipient) private view returns (uint16, uint256) {
		Grant storage tokenGrant = tokenGrants[_recipient];

		require(tokenGrant.totalClaimed < tokenGrant.amount, "grant fully claimed");

		// For grants created with a future start date, that hasn't been reached, return 0, 0
		if (currentTime() < tokenGrant.startTime) {
			return (0, 0);
		}

		// Check cliff was reached
		uint256 elapsedDays = block.timestamp.sub(tokenGrant.startTime - 1 days).div(1 days);

		// If over vesting duration, all tokens vested
		if (elapsedDays >= tokenGrant.vestingDuration) {
			uint256 remainingGrant = tokenGrant.amount.sub(tokenGrant.totalClaimed);
			return (tokenGrant.vestingDuration, remainingGrant);
		} else {
			uint16 daysVested = uint16(elapsedDays.sub(tokenGrant.daysClaimed));
			uint256 amountVestedPerDay = tokenGrant.amount.div(uint256(tokenGrant.vestingDuration));
			uint256 amountVested = uint256(daysVested.mul(amountVestedPerDay));
			return (daysVested, amountVested);
		}
	}

	function currentTime() private view returns (uint256) {
		return block.timestamp;
	}
}
