pragma solidity ^0.8.2;

import "Ownable.sol";
import "IERC20.sol";

import "IVesting.sol";

contract Vesting is Ownable, IVesting {

	struct Vehicule {
		bool 	updateable;
		uint256 start;
		uint256 end;
		uint256 upfront;
		uint256 amount;
		uint256 claimed;
		uint256 claimedUpfront;
	}

	address public override co;

	mapping(address => mapping(uint256 => Vehicule)) public override vehicules;
	mapping(address => uint256) public override vehiculeCount;

	event YieldClaimed(address indexed user, uint256 amount);
	event VehiculeCreated(address indexed user, uint256 id, uint256 amount, uint256 start, uint256 end);

	constructor(address _co) {
		require(_co != address(0));
		co = _co;
	}

	function min(uint256 a, uint256 b) pure private returns(uint256) {
		return a < b ? a : b;
	}

	function max(uint256 a, uint256 b) pure private returns(uint256) {
		return a > b ? a : b;
	}

	function createVehicule(address _user, uint256 _amount, uint256 _upfront, uint256 _start, uint256 _end, bool _updateable) external onlyOwner returns(uint256){
		require(_end > _start, "Vesting: wrong vehicule parametres");
		require(_start > 0, "Vesting: start cannot be 0");

		uint256 counter = vehiculeCount[_user];
		vehicules[_user][counter] = Vehicule(_updateable, _start, _end, _upfront, _amount, 0, 0);
		vehiculeCount[_user]++;
		emit VehiculeCreated(_user, counter, _amount + _upfront, _start, _end);
	}

	function killVehicule(address _user, uint256 _index) external onlyOwner {
		require(vehicules[_user][_index].updateable, "Vesting: Can't kill");
		delete vehicules[_user][_index];
	}

	function endVehicule(address _user, uint256 _index) external onlyOwner {
		Vehicule storage vehicule = vehicules[_user][_index];
		require(vehicule.updateable, "Vesting: Cannot end");
		uint256 _now = block.timestamp;
		uint256 start = vehicule.start;
		if (start == 0)
			revert("Vesting: vehicule does not exist");
		uint256 end = vehicule.end;
		uint256 elapsed = min(end, max(_now, vehicule.start)) - start;
		uint256 maxDelta = end - start;
		uint256 unlocked = vehicule.amount * elapsed / maxDelta;
		if (_now > start) {
			vehicule.amount = unlocked;
			vehicule.end = min(vehicule.end, _now);
		}
		else {
			vehicule.upfront = 0;
			vehicule.amount = 0;
		}
	}

	function fetchTokens(uint256 _amount) external onlyOwner {
		IERC20(co).transfer(msg.sender, _amount);
	}

	function claim(uint256 _index) external override {
		uint256 _now = block.timestamp;
		
		Vehicule storage vehicule = vehicules[msg.sender][_index];

		uint256 upfront = _claimUpfront(vehicule);
		uint256 start = vehicule.start;
		if (start == 0)
			revert("Vesting: vehicule does not exist");
		require(_now > start, "Vesting: cliff !started");
		uint256 end = vehicule.end;
		uint256 elapsed = min(end, _now) - start;
		uint256 maxDelta = end - start;
		// yield = amount * delta / vest_duration - claimed_amount
		uint256 yield = (vehicule.amount * elapsed / maxDelta) - vehicule.claimed;
		vehicule.claimed += yield;
		IERC20(co).transfer(msg.sender, yield + upfront);
		emit YieldClaimed(msg.sender, yield);
	}

	function _claimUpfront(Vehicule storage vehicule) private returns(uint256) {
		uint256 upfront = vehicule.upfront;
		if (upfront > 0) {
			vehicule.upfront = 0;
			vehicule.claimedUpfront = upfront;
			return upfront;
		}
		return 0;
	}

	function balanceOf(address _user) external view returns(uint256 totalVested) {
		uint256 vehiculeCount = vehiculeCount[msg.sender];
		for (uint256 i = 0; i < vehiculeCount; i++) {
			Vehicule memory vehicule = vehicules[msg.sender][i];
			totalVested = totalVested + pendingReward(msg.sender, i);
		}
	}

	function pendingReward(address _user, uint256 _index) public override view returns(uint256) {
		Vehicule memory vehicule = vehicules[_user][_index];
		uint256 elapsed = min(vehicule.end, block.timestamp) - vehicule.start;
		uint256 maxDelta = vehicule.end - vehicule.start;
		return vehicule.amount * elapsed / maxDelta - vehicule.claimed + vehicule.upfront;
	}

	function claimed(address _user, uint256 _index) external view override returns(uint256) {
		Vehicule memory vehicule = vehicules[_user][_index];
		return vehicule.claimed + vehicule.claimedUpfront;
	}
}