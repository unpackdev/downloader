// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "./Address.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IStaker.sol";
import "./IZap.sol";
import "./IMigration.sol";

contract StakingLP is Ownable {
	struct Share {
		uint depositTime;
		uint initialDeposit;
		uint sumETH;
	}

	mapping(address => Share) public shares;
	uint public sumETH;
	uint private constant PRECISION = 1e18;
	uint public totalETH;
	uint public totalLP;
	uint public immutable delay;
	IERC20 public constant lp = IERC20(0x4bF57E609051e894B9BF8065C94bd3cE700F4459);
	IStaker public immutable staker;
	IZap public zap; // updateable if better algorithm discovered
	uint public startTime;
	uint private isZapping = 2; // boolean allowing this contract to receive eth without depositing it
	address public migration;

	constructor(IStaker staker_, IZap zap_, uint delay_) {
		staker = staker_;
		zap = zap_;
		delay = delay_;
	}

	receive() external payable {
		if (msg.sender == address(staker) || msg.sender == owner()) _distribute();
		else if (isZapping == 2) _deposit();
	}

	function _distribute() internal {
		if (msg.value == 0) return;

		uint totalLPCached = totalLP;
		if (totalLPCached == 0) return Address.sendValue(payable(msg.sender), msg.value);

		uint gpus = msg.value * PRECISION / totalLPCached;
		sumETH += gpus;
		totalETH += msg.value;
	}

	function _deposit() internal {
		require(startTime != 0, "not started");
		require(msg.value > 0, "Amount must be greater than zero");
		Share memory share = shares[msg.sender];

		// gas + slippage handled with maxZapReverseRatio
		isZapping = 1;
		// amount eth not used for adding lp sent to initiator while avoiding reentrency
		(uint amountLP, uint amountETH) = zap.zapInETH{value: msg.value}();
		isZapping = 2;

		uint gains = _computeGainsUpdateShare(msg.sender, share, share.initialDeposit + amountLP, true, false);
		_sendETH(msg.sender, gains + amountETH);
	}

	function withdraw() external {
		Share memory share = shares[msg.sender];
		require(share.initialDeposit > 0, "No initial deposit");
		require(share.depositTime + delay < block.timestamp, "withdraw too soon");

		// returns lp - allow withdrawal even if zap set to wrong address
		lp.transfer(msg.sender, share.initialDeposit);
		uint gains = _computeGainsUpdateShare(msg.sender, share, 0, true, true);
		_sendETH(msg.sender, gains);
	}

	function claim() external {
		Share memory share = shares[msg.sender];
		require(share.initialDeposit > 0, "No initial deposit");
		uint gains = _computeGainsUpdateShare(msg.sender, share, share.initialDeposit, false, false);
		_sendETH(msg.sender, gains);
	}

	// if logic updated
	function migrate() external {
		require(migration != address(0), "no migration");
		Share memory share = shares[msg.sender];
		require(share.initialDeposit > 0, "No initial deposit");

		// returns lp - allow withdrawal even if zap set to wrong address
		lp.transfer(migration, share.initialDeposit);
		IMigration(migration).migrate(msg.sender, share.depositTime, share.initialDeposit);
		uint gains = _computeGainsUpdateShare(msg.sender, share, 0, true, true);
		_sendETH(msg.sender, gains);
	}

	function _sendETH(address to, uint amount) private {
		if (amount > 0) Address.sendValue(payable(to), amount);
	}

	// can be updated as only zapInETH implemented or if better algorithm
	function updateZap(IZap zap_) external onlyOwner {
		// new deposit may fail if wrongly set
		zap = zap_;
	}

	// can be implemented for user flexibility if updated logic
	function updateMigration(address migration_) external onlyOwner {
		migration = migration_;
	}
	
	// if someone sends LP tokens or REFLEX to the contract
	function recoverTokens(IERC20 token, uint amount) external onlyOwner {
		if (token == lp) {
			assert(token.balanceOf(address(this)) >= totalLP + amount);
		}
		token.transfer(owner(), amount);
	}
	
	function start() external onlyOwner {
		assert(startTime == 0);
		startTime = block.timestamp;
	}

	function _computeGainsUpdateShare(address who, Share memory share, uint newAmount, bool resetTimer, bool withdrawn) 
		private 
		returns (uint gains)
	{
		staker.claimAndDistribute();

		if (share.initialDeposit != 0) gains = share.initialDeposit * (sumETH - share.sumETH) / PRECISION;

		if (newAmount == 0) delete shares[who];
		else if (resetTimer) shares[who] = Share(block.timestamp, newAmount, sumETH);
		else shares[who] = Share(share.depositTime, newAmount, sumETH);

		if (withdrawn) totalLP -= share.initialDeposit;
		else if (newAmount != share.initialDeposit) totalLP += (newAmount - share.initialDeposit);
	}

	function pending(address who) external view returns (uint) {
		Share memory share = shares[who];
		uint sumETHUpdated = sumETH + staker.pending(address(this)) * PRECISION / totalLP;
		return share.initialDeposit * (sumETHUpdated - share.sumETH) / PRECISION;
	}
}
