pragma solidity =0.6.6;

import "./SafeMath.sol";
import "./IImx.sol";
import "./IClaimable.sol";

abstract contract Distributor is IClaimable {
	using SafeMath for uint;

	address public immutable imx;
	address public immutable claimable;

	struct Recipient {
		uint shares;
		uint lastShareIndex;
		uint credit;
	}
	mapping(address => Recipient) public recipients;
	
	uint public totalShares;
	uint public shareIndex;
	
	event UpdateShareIndex(uint shareIndex);
	event UpdateCredit(address indexed account, uint lastShareIndex, uint credit);
	event Claim(address indexed account, uint amount);
	event EditRecipient(address indexed account, uint shares, uint totalShares);

	constructor (
		address imx_,
		address claimable_
	) public {
		imx = imx_;
		claimable = claimable_;
	}
	
	function updateShareIndex() public virtual nonReentrant returns (uint _shareIndex) {
		if (totalShares == 0) return shareIndex;
		uint amount = IClaimable(claimable).claim();
		if (amount == 0) return shareIndex;
		_shareIndex = amount.mul(2**160).div(totalShares).add(shareIndex);
		shareIndex = _shareIndex;
		emit UpdateShareIndex(_shareIndex);
	}
	
	function updateCredit(address account) public returns (uint credit) {
		uint _shareIndex = updateShareIndex();
		if (_shareIndex == 0) return 0;
		Recipient storage recipient = recipients[account];
		credit = recipient.credit + _shareIndex.sub(recipient.lastShareIndex).mul(recipient.shares) / 2**160;
		recipient.lastShareIndex = _shareIndex;
		recipient.credit = credit;
		emit UpdateCredit(account, _shareIndex, credit);
	}

	function claimInternal(address account) internal virtual returns (uint amount) {
		amount = updateCredit(account);
		if (amount > 0) {
			recipients[account].credit = 0;
			IImx(imx).transfer(account, amount);
			emit Claim(account, amount);
		}
	}

	function claim() external virtual override returns (uint amount) {
		return claimInternal(msg.sender);
	}
	
	function editRecipientInternal(address account, uint shares) internal {
		updateCredit(account);
		Recipient storage recipient = recipients[account];
		uint prevShares = recipient.shares;
		uint _totalShares = shares > prevShares ? 
			totalShares.add(shares - prevShares) : 
			totalShares.sub(prevShares - shares);
		totalShares = _totalShares;
		recipient.shares = shares;
		emit EditRecipient(account, shares, _totalShares);
	}
	
	// Prevents a contract from calling itself, directly or indirectly.
	bool internal _notEntered = true;
	modifier nonReentrant() {
		require(_notEntered, "Distributor: REENTERED");
		_notEntered = false;
		_;
		_notEntered = true;
	}
}