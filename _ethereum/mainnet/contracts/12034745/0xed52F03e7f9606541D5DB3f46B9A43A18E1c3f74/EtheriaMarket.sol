pragma solidity ^0.7.6;

import "./AccessControl.sol";
import "./SafeMath.sol";

interface MapElevationRetriever {
	function getElevation(uint8 col, uint8 row) external view returns (uint8);
}

interface Etheria{
	function getOwner(uint8 col, uint8 row) external view returns(address);
	function setOwner(uint8 col, uint8 row, address newowner) external;
}

contract EtheriaMarket is AccessControl {

	/*
	Marketplace based on the Larvalabs OGs!
	*/

	using SafeMath for uint256;

	string public name = "EtheriaMarket";
	uint public constant mapSize = 33;

	Etheria public constant etheria = Etheria(0xB21f8684f23Dbb1008508B4DE91a0aaEDEbdB7E4);

	uint public FEE = 20; //5%
	uint public feesToCollect = 0;

    struct Bid {
        uint8 col;
		uint8 row;
		uint amount;
        address bidder;
    }

    // A record of the highest Etheria bid
    mapping (uint => Bid) public bids;
	mapping (address => uint) public pendingWithdrawals;

    event EtheriaTransfer(uint indexed index, address from, address to);
    event EtheriaBidCreated(uint indexed index, uint amount, address bidder);
    event EtheriaBidWithdrawn(uint indexed index, uint amount, address bidder);
    event EtheriaBought(uint indexed index, uint amount, address seller, address bidder);

    constructor() public {
		_setupRole(DEFAULT_ADMIN_ROLE, 0x568f02EE272909ae9352188D4EA406Df810Ba4dE);
		_setupRole(DEFAULT_ADMIN_ROLE, 0x9260ae742F44b7a2e9472f5C299aa0432B3502FA);
		_setupRole(DEFAULT_ADMIN_ROLE, 0xD2927a91570146218eD700566DF516d67C5ECFAB);
    }

	function collectFees() public {
		require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
		uint amount = feesToCollect;
		uint third = amount.div(3);
		feesToCollect = 0;
		uint remainder = amount.sub(third).sub(third);
		payable(0x568f02EE272909ae9352188D4EA406Df810Ba4dE).transfer(third);
		payable(0x9260ae742F44b7a2e9472f5C299aa0432B3502FA).transfer(third);
		payable(0xD2927a91570146218eD700566DF516d67C5ECFAB).transfer(remainder);
	}

	function changeFee(uint newFee) public {
		require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
		FEE = newFee;
	}

	function _index(uint8 col, uint8 row) internal view returns (uint) {
		return col * mapSize + row;
	}

	function bid(uint8 col, uint8 row) public payable {
		//require(etheria.getOwner(col, row) != msg.sender);
		uint index = _index(col, row);
		require(msg.value > 0, "BID::Value is 0");
		Bid memory bid = bids[index];
		require(msg.value > bid.amount, "BID::New bid too low");
		//refund failing bid
		pendingWithdrawals[bid.bidder] += bid.amount;
		//new bid
		bids[index] = Bid(col, row, msg.value, msg.sender);
		emit EtheriaBidCreated(index, msg.value, msg.sender);
	}

	function withdrawBid(uint8 col, uint8 row) public {
		uint index = _index(col, row);
		Bid memory bid = bids[index];
		require(msg.sender == bid.bidder, "WITHDRAW_BID::Only bidder can withdraw his bid");
		emit EtheriaBidWithdrawn(index, bid.amount, msg.sender);
		uint amount = bid.amount;
		bids[index] = Bid(col, row, 0, address(0x0));
		msg.sender.transfer(amount);
	}

	function acceptBid(uint8 col, uint8 row, uint minPrice) public {
		require(etheria.getOwner(col, row) == msg.sender, "ACCEPT_BID::Only owner can accept bid");
		uint index = _index(col, row);
        Bid memory bid = bids[index];
		require(bid.amount > 0, "ACCEPT_BID::Bid amount is 0");
		require(bid.amount >= minPrice, "ACCEPT_BID::Min price not respected");
		// With the require getOwner we check already, if it can be assigned, no other checks needed
		etheria.setOwner(col, row, bid.bidder);

		//collect fee
		uint fees = bid.amount.div(FEE);
		feesToCollect += fees;

        uint amount = bid.amount.sub(fees);
		bids[index] = Bid(col, row, 0, address(0x0));
        pendingWithdrawals[msg.sender] += amount;
        emit EtheriaBought(index, amount, msg.sender, bid.bidder);
		emit EtheriaTransfer(index, msg.sender, bid.bidder);
    }

	function withdraw() public {
		uint amount = pendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
	}
}