pragma solidity =0.6.6;

import "./Distributor.sol";
import "./IBorrowTracker.sol";
import "./IVester.sol";
import "./Math.sol";

// ASSUMTPIONS:
// - advance is called at least once for each epoch
// - farmingPool shares edits are effective starting from the next epoch

contract FarmingPool is IBorrowTracker, Distributor {

	address public immutable borrowable;

	uint public immutable vestingBegin;
	uint public immutable segmentLength;
	
	uint public epochBegin;
	uint public epochAmount;
	uint public lastUpdate;
	
	event UpdateShareIndex(uint shareIndex);
	event Advance(uint epochBegin, uint epochAmount);
	
	constructor (
		address imx_,
		address claimable_,
		address borrowable_,
		address vester_
	) public Distributor(imx_, claimable_) {
		borrowable = borrowable_;
		uint _vestingBegin = IVester(vester_).vestingBegin();
		vestingBegin = _vestingBegin;
		segmentLength = IVester(vester_).vestingEnd().sub(_vestingBegin).div(IVester(vester_).segments());
	}
	
	function updateShareIndex() public virtual override returns (uint _shareIndex) {
		if (totalShares == 0) return shareIndex;
		if (epochBegin == 0) return shareIndex;
		uint epochEnd = epochBegin + segmentLength;
		uint blockTimestamp = getBlockTimestamp();
		uint timestamp = Math.min(blockTimestamp, epochEnd);
		uint timeElapsed = timestamp - lastUpdate;
		assert(timeElapsed <= segmentLength);
		if (timeElapsed == 0) return shareIndex;
		
		uint amount =  epochAmount.mul(timeElapsed).div(segmentLength);
		_shareIndex = amount.mul(2**160).div(totalShares).add(shareIndex);
		shareIndex = _shareIndex;
		lastUpdate = timestamp;
		emit UpdateShareIndex(_shareIndex);
	}
	
	function advance() public nonReentrant {
		uint blockTimestamp = getBlockTimestamp();
		if (blockTimestamp < vestingBegin) return;
		uint _epochBegin = epochBegin;
		if (_epochBegin != 0 && blockTimestamp < _epochBegin + segmentLength) return;
		uint amount = IClaimable(claimable).claim();
		if (amount == 0) return;
		updateShareIndex();		
		uint timeSinceBeginning = blockTimestamp - vestingBegin;
		epochBegin = blockTimestamp.sub(timeSinceBeginning.mod(segmentLength));
		epochAmount = amount;
		lastUpdate = epochBegin;
		emit Advance(epochBegin, epochAmount);
	}

	function claimInternal(address account) internal override returns (uint amount) {
		advance();
		return super.claimInternal(account);
	}
	
	function claimAccount(address account) external returns (uint amount) {
		return claimInternal(account);
	}
	
	function trackBorrow(address borrower, uint borrowBalance, uint borrowIndex) external override {
		require(msg.sender == borrowable, "FarmingPool: UNAUTHORIZED");
		uint newShares = borrowBalance.mul(2**96).div(borrowIndex);
		editRecipientInternal(borrower, newShares);
	}
	
	function getBlockTimestamp() public virtual view returns (uint) {
		return block.timestamp;
	}
}