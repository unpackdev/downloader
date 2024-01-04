// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "./Latinum.sol";
import "./Dilithium.sol";
import "./Math.sol";

/// Claim represents a bidder's claim to a bidding
/// period Latinum supply.
struct Claim {
    uint256 period;
    uint256 bid;
}

/// @dev Period represents an auction period
struct Period {
    uint256 endTime;
    uint256 ltnSupply;
    uint256 totalBids;
}

/// @author The MakeOS Team
/// @title The contract that provides the Latinum dutch auction functionality.
contract Auction is Latinum(address(0)) {
    // periods contain the auction periods
    Period[] public periods;

    // claims store all bidders Latinum claims
    mapping(address => Claim[]) public claims;

    // MAX_PERIODS is the maximum allowed periods
    uint256 public maxPeriods;

    // numPeriods keeps count of the number of periods
    uint256 public numPeriods;

    // ltnSupplyPerPeriod is the maximum amount of LTN distributed per auction.
    uint256 public ltnSupplyPerPeriod;

    // minBid is the minimum bid
    uint256 public minBid;

    // fee is the auction fee paid for each DIL in a bid.
    uint256 public fee;

    // fundingAddress is the address where contract fund can be transfered to.
    address public fundingAddress;

    // minReqDILSupply is the amount of DIL supply required to create the first period.
    uint256 public minReqDILSupply;

    event NewPeriod(uint256 index, uint256 endTime);
    event NewBid(address addr, uint256 amount, uint256 periodIndex);
    event NewClaim(address addr, uint256 amount, uint256 index);

    /// @dev isAuctionClosed is a modifier to check if the auction has closed.
    modifier isAuctionClosed() {
        require(
            periods.length < uint256(maxPeriods) ||
                periods[periods.length - 1].endTime > block.timestamp,
            "Auction has closed"
        );
        _;
    }

    /// @dev isBidAmountUnlocked is a modifier to check if a bidder has unlocked
    /// the bid amount
    modifier isBidAmountUnlocked(address bidder, uint256 bidAmt) {
        // Ensure the bidder has unlocked the bid amount
        uint256 allowance = dil.allowance(bidder, address(this));
        require(allowance >= bidAmt, "Amount not unlocked");
        _;
    }

    /// @notice The constructor
    /// @param _dilAddress is the address of the Dilithium contract.
    /// @param _minReqDILSupply is minimum number of DIL supply required to start a
    //  bid period.
    /// @param _maxPeriods is the number of auction periods.
    /// @param _ltnSupplyPerPeriod is the supply of Latinum per period.
    /// @param _minBid is minimum bid per period.
    /// @param _fee is the auction fee
    constructor(
        address _dilAddress,
        uint256 _minReqDILSupply,
        uint256 _maxPeriods,
        uint256 _ltnSupplyPerPeriod,
        uint256 _minBid,
        address _fundingAddress,
        uint256 _fee
    ) public {
        dil = Dilithium(_dilAddress);
        minBid = _minBid;
        maxPeriods = _maxPeriods;
        ltnSupplyPerPeriod = _ltnSupplyPerPeriod;
        minReqDILSupply = _minReqDILSupply;
        fundingAddress = _fundingAddress;
        fee = _fee;
    }

    receive() external payable {}

    fallback() external payable {}

    /// @dev setFee sets the auction fee.
    /// @param _fee is the new auction fee.
    function setFee(uint256 _fee) public isOwner() {
        fee = _fee;
    }

    /// @dev setFundingAddress sets the funding address
    /// @param addr is the address to change to.
    function setFundingAddress(address addr) public isOwner() {
        fundingAddress = addr;
    }

    /// @dev withdraw sends ETH to the funding address.
    /// @param amount is the amount to be withdrawn.
    function withdraw(uint256 amount) external {
        require(msg.sender == fundingAddress, "Not authorized");
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }

    /// @notice makePeriod creates and returns a period. If the
    /// most recent period has not ended, it is returned instead
    /// of creating a new one.
    function makePeriod() public isAuctionClosed() returns (uint256) {
        require(
            periods.length > 0 || dil.totalSupply() >= minReqDILSupply,
            "Minimum Dilithium supply not reached"
        );

        Period memory period;
        uint256 index;

        // If no period, create one
        if (periods.length == 0) {
            period = Period(block.timestamp + 24 hours, ltnSupplyPerPeriod, 0);
            periods.push(period);
            index = periods.length - 1;
            numPeriods++;
            emit NewPeriod(index, period.endTime);
        }

        // Get the current period
        if (period.endTime == 0 && periods.length > 0) {
            period = periods[periods.length - 1];
            index = periods.length - 1;
        }

        // If period has ended, start a new one
        if (period.endTime <= block.timestamp) {
            period = Period(block.timestamp + 24 hours, ltnSupplyPerPeriod, 0);
            periods.push(period);
            index = periods.length - 1;
            numPeriods++;
            emit NewPeriod(index, period.endTime);
        }

        return index;
    }

    /// @dev updatePeriodTotalBids updates the total bid of a period.
    function updatePeriodTotalBids(uint256 idx, uint256 newBid) internal {
        periods[idx].totalBids = SM.add(periods[idx].totalBids, newBid);
    }

    /// @notice bid lets an account place a bid.
    /// @param bidAmt is the amount of the DIL to be placed as bid. This amount
    /// must have been unlocked in the DIL contract.
    function bid(uint256 bidAmt)
        public
        payable
        isAuctionClosed()
        isBidAmountUnlocked(msg.sender, bidAmt)
        returns (bool)
    {
        require(getNumOfClaims() + 1 <= 5, "Too many unprocessed claims");
        uint256 index = makePeriod();

        if (
            (index <= 6 && bidAmt < minBid) ||
            (index > 6 && bidAmt < minBid * 50)
        ) {
            revert("Bid amount too small");
        }

        if ((index <= 6 && bidAmt > minBid * 10)) {
            revert("Bid amount too high");
        }

        if (index > 6 && msg.value < (bidAmt / 1 ether) * fee) {
            revert("Auction fee too low");
        }

        // Burn the the bid amount
        dil.transferFrom(msg.sender, address(this), bidAmt);
        dil.burn(bidAmt);

        // Increase the period's bid count
        updatePeriodTotalBids(index, bidAmt);

        // Add a new claim
        claims[msg.sender].push(Claim(index, bidAmt));

        emit NewBid(msg.sender, bidAmt, index);

        return true;
    }

    /// @dev getNumOfPeriods returns the number of periods.
    function getNumOfPeriods() public view returns (uint256) {
        return periods.length;
    }

    /// @dev getNumOfClaims returns the number of claims the sender has.
    function getNumOfClaims() public view returns (uint256 n) {
        for (uint256 i = 0; i < claims[msg.sender].length; i++) {
            if (claims[msg.sender][i].bid > 0) {
                n++;
            }
        }
    }

    /// @dev getNumOfClaimsOfAddr returns the number of an address.
    function getNumOfClaimsOfAddr(address addr)
        public
        view
        returns (uint256 n)
    {
        for (uint256 i = 0; i < claims[addr].length; i++) {
            if (claims[addr][i].bid > 0) {
                n++;
            }
        }
    }

    /// @dev claim
    function claim() public {
        uint256 nClaims = claims[msg.sender].length;
        uint256 deleted = 0;
        for (uint256 i = 0; i < nClaims; i++) {
            Claim memory claim_ = claims[msg.sender][i];
            if (claim_.bid == 0) {
                deleted++;
                continue;
            }

            // Skip claim in current, unexpired period
            Period memory period = periods[claim_.period];
            if (period.endTime > block.timestamp) {
                continue;
            }

            // Delete claim
            delete claims[msg.sender][i];
            deleted++;

            // Get base point for the claim
            uint256 bps = SM.getBPSOfAInB(claim_.bid, period.totalBids);
            uint256 ltnReward = (period.ltnSupply * bps) / 10000;
            _mint(msg.sender, ltnReward);

            emit NewClaim(msg.sender, ltnReward, claim_.period);
        }

        if (deleted == nClaims) {
            delete claims[msg.sender];
        }
    }

    /// @dev transferUnallocated transfers unallocated Latinum supply to an
    /// account.
    /// @param to is the account to transfer to.
    /// @param amt is the amount to tranfer.
    function transferUnallocated(address to, uint256 amt) public isOwner() {
        require(
            periods.length == maxPeriods &&
                periods[periods.length - 1].endTime <= block.timestamp,
            "Auction must end"
        );

        uint256 remaining = SM.sub(maxSupply, totalSupply());
        require(remaining >= amt, "Insufficient remaining supply");
        _mint(to, amt);
    }

    /// @dev setMaxPeriods updates the number of auction periods.
    /// @param n is the new number of periods
    function setMaxPeriods(uint256 n) public isOwner() {
        maxPeriods = n;
    }

    /// @dev setMinReqDILTotalSupply updates the required min DIL supply.
    /// @param n is the new value
    function setMinReqDILTotalSupply(uint256 n) public isOwner() {
        minReqDILSupply = n;
    }
}
