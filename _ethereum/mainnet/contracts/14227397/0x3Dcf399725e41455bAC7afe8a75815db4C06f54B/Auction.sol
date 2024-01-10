// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "Ownable.sol";
import "Pausable.sol";
import "SafeMath.sol";
import "IAllocationMinter.sol";

contract Auction is Ownable, Pausable {
    using SafeMath for uint;

    IAllocationMinter public immutable token;
    bytes32 public immutable allocationRole;

    // project-specific multisig address where raised funds will be sent
    address payable destAddress;

    uint public secondsPerAuction;
    uint public currentAuction;
    uint public currentAuctionEndTime;
    uint public totalContributed;
    uint public totalEmitted;
    uint public ewma;

    // The number of participants in a particular auction.
    mapping(uint => uint) public auctionMemberCount;
    // The participants in a particular auction.
    mapping(uint => address[]) public auctionMembers;
    // The total units contributed in a particular auction.
    mapping(uint => uint) public auctionUnits;
    // The remaining unclaimed units from a particular auction.
    mapping(uint => uint) public auctionUnitsRemaining;
    // All tokens auctioned in a paticular auction.
    mapping(uint => uint) public auctionSupply;
    // The remaining unclaimed tokens from a particular auction.
    mapping(uint => uint) public auctionSupplyRemaining;
    // Participant's remaining (unclaimed) units for a particular auction.
    mapping(uint => mapping(address => uint)) public auctionMemberUnitsRemaining;
    // Participant's particular auctions.
    mapping(address => uint[]) public memberAuctions;

    // Events
    event NewAuction(uint auction, uint endTime, uint previousAuctionTotal, uint previousAuctionEmission, uint historicEWMA, uint previousAuctionMembers);
    event Contribution(address indexed payer, address indexed member, uint auction, uint units, uint dailyTotal);
    event Claim(address indexed caller, address indexed member, uint auction, uint value, uint remaining);

    constructor(address payable daoMultisig, IAllocationMinter token_, bytes32 allocationRole_, uint secondsPerAuction_) {
        require(address(daoMultisig) != address(0), "Invalid daoMultisig address");
        require(address(token_) != address(0), "Invalid token_ address");

        _transferOwnership(daoMultisig);

        token = token_;
        allocationRole = allocationRole_;
        destAddress = daoMultisig;
        secondsPerAuction = secondsPerAuction_;
        currentAuction = 1;
        currentAuctionEndTime = block.timestamp + secondsPerAuction;
        require(token_.allocationMinted(allocationRole_) == 0, "auction allocation must have a clean slate");
        uint256 available = token_.allocationSupplyAt(allocationRole_, currentAuctionEndTime);
        auctionSupply[currentAuction] = available;
        auctionSupplyRemaining[currentAuction] = available;
    }

    function setDestAddress(address payable destAddress_)
        public
        onlyOwner()
    {
        require(address(destAddress_) != address(0), "invalid destAddress_");
        destAddress = destAddress_;
    }

    receive()
        external payable
        whenNotPaused
    {
        _contributeFor(msg.sender);
    }

    function contributeFor(address member)
        external payable
        whenNotPaused
    {
        _contributeFor(member);
    }

    function auctionsContributed(address member)
        public view
        returns (uint)
    {
        return memberAuctions[member].length;
    }

    function claim()
        external
        whenNotPaused
        returns (uint value)
    {
        _checkpoint();
        uint length = memberAuctions[msg.sender].length;
        for (uint i = 0; i < length; ++i) {
            uint auction = memberAuctions[msg.sender][i];
            if (auction < currentAuction) {
                uint memberUnits = auctionMemberUnitsRemaining[auction][msg.sender];
                if (memberUnits != 0) {
                    value += _prepareClaim(auction, msg.sender, memberUnits);
                }
            }
        }
        _mint(msg.sender, value);
    }

    function emissionShare(uint auction, address member)
        public view
        returns (uint value)
    {
        uint memberUnits = auctionMemberUnitsRemaining[auction][member];
        if (memberUnits != 0) {
            uint totalUnits = auctionUnitsRemaining[auction];
            uint emissionRemaining = auctionSupplyRemaining[auction];
            value = (emissionRemaining * memberUnits) / totalUnits;
        }
    }

    function impliedPriceEWMA(bool includeCurrent) public view returns (uint) {
        return ewma == 0 || includeCurrent ? computeEWMA() : ewma;
    }

    function computeEWMA() public view returns (uint) {
        uint price = 10**9 * (auctionUnits[currentAuction] / (auctionSupply[currentAuction] / 10**9));
		return ewma == 0 ? price : (7 * price + 3 * ewma) / 10; // alpha = 0.7
    }

    function checkpoint() external {
        _checkpoint();
    }

    function pause()
        public
        onlyOwner()
        whenNotPaused
    {
        _pause();
    }

    function unpause()
        public
        onlyOwner()
        whenPaused
    {
        _unpause();
    }

    function _checkpoint()
        private
    {
        if (block.timestamp >= currentAuctionEndTime) {
            uint units = auctionUnits[currentAuction];
            uint emission = auctionSupply[currentAuction];
			if (units > 0) {
				ewma = computeEWMA();
			}
            uint members = auctionMemberCount[currentAuction];
            currentAuctionEndTime = block.timestamp + secondsPerAuction;
            uint256 available = token.allocationSupplyAt(allocationRole, currentAuctionEndTime) - auctionSupply[currentAuction];

            currentAuction += 1;
            auctionSupply[currentAuction] = available;
            auctionSupplyRemaining[currentAuction] = available;

            emit NewAuction(currentAuction, currentAuctionEndTime, units, emission, ewma, members);
        }
    }

    function _contributeFor(address member)
        private
    {
        require(msg.value > 0, "ETH required");
        _checkpoint();
        _claimPrior(member);
        if (auctionMemberUnitsRemaining[currentAuction][member] == 0) {
            // If hasn't contributed to this Auction yet
            memberAuctions[member].push(currentAuction);
            auctionMemberCount[currentAuction] += 1;
            auctionMembers[currentAuction].push(member);
        }
        auctionMemberUnitsRemaining[currentAuction][member] += msg.value;
        auctionUnits[currentAuction] += msg.value;
        auctionUnitsRemaining[currentAuction] += msg.value;
        totalContributed += msg.value;
        (bool success,) = destAddress.call{value: msg.value}("");
        require(success, "");
        emit Contribution(msg.sender, member, currentAuction, msg.value, auctionUnits[currentAuction]);
    }

    function _claimPrior(address member) private {
        uint i = memberAuctions[member].length;
        while (i > 0) {
            --i;
            uint auction = memberAuctions[member][i];
            if (auction < currentAuction) {
                uint units = auctionMemberUnitsRemaining[auction][member];
                if (units > 0) {
                    _mint(member, _prepareClaim(auction, member, units));
                    //
                    // If a prior auction is found, then it is the only prior auction
                    // that has not already been withdrawn, so there's nothing left to do.
                    //
                    return;
                }
            }
        }
    }

    function _prepareClaim(uint _auction, address _member, uint memberUnits)
        private
        returns (uint value)
    {
        uint totalUnits = auctionUnitsRemaining[_auction];
        uint emissionRemaining = auctionSupplyRemaining[_auction];
        value = (emissionRemaining * memberUnits) / totalUnits;
        auctionMemberUnitsRemaining[_auction][_member] = 0; // since it will be withdrawn
        auctionUnitsRemaining[_auction] = auctionUnitsRemaining[_auction].sub(memberUnits);
        auctionSupplyRemaining[_auction] = auctionSupplyRemaining[_auction].sub(value);
        emit Claim(msg.sender, _member, _auction, value, auctionSupplyRemaining[_auction]);
    }
    
    function _mint(address member, uint value)
        private
    {
        token.allocationMint(member, allocationRole, value);
    }
}
