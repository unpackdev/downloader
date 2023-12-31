// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RevShareContract {
    address public owner;
    address public incentivesAddress;

    uint256 public currentRound = 0; // Keeps track of the current round

    struct Round {
        uint256 revenueForBB;
        uint256 revenueForBettingVolume;
        uint256 revenueForReferrals;
        uint256 totalBBTokens;
        uint256 totalBettingVolume;
        uint256 totalReferrals;
        bool isSnapshotUploaded;
        mapping(address => uint256) snapshotBBBalances;
        mapping(address => uint256) snapshotBettingVolume;
        mapping(address => uint256) snapshotReferrals;
        mapping(address => bool) hasClaimed;
    }

    mapping(uint256 => Round) public rounds;

    event EthClaim(address indexed claimer, uint256 amount, uint256 round);
    event AdminWithdraw(uint256 amount, uint256 round);

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor(address _incentivesAddress) {
        owner = msg.sender;
        incentivesAddress = _incentivesAddress;
    }

    function depositRevenue(uint256 bbRevenue, uint256 bettingVolumeRevenue, uint256 referralsRevenue, uint256 incentivesRevenue) external payable onlyOwner {
    require(msg.value == bbRevenue + bettingVolumeRevenue + referralsRevenue + incentivesRevenue, "Mismatch in sent value and declared revenue distribution.");
    currentRound += 1;
    
    rounds[currentRound].revenueForBB = bbRevenue;
    rounds[currentRound].revenueForBettingVolume = bettingVolumeRevenue;
    rounds[currentRound].revenueForReferrals = referralsRevenue;

    payable(incentivesAddress).transfer(incentivesRevenue); // send specified amount to the incentives address immediately
}


    function uploadBBBalances(address[] calldata bbHolders, uint256[] calldata bbBalances) external onlyOwner {
    require(currentRound > 0, "Deposit revenue first");
    Round storage r = rounds[currentRound];
    require(!r.isSnapshotUploaded, "Snapshot already uploaded for this round");

    for (uint256 i = 0; i < bbHolders.length; i++) {
        r.snapshotBBBalances[bbHolders[i]] = bbBalances[i];
        r.totalBBTokens += bbBalances[i];
    }
}

function uploadBettingVolumes(address[] calldata betters, uint256[] calldata bettingVolumes) external onlyOwner {
    require(currentRound > 0, "Deposit revenue first");
    Round storage r = rounds[currentRound];
    require(!r.isSnapshotUploaded, "Snapshot already uploaded for this round");

    for (uint256 i = 0; i < betters.length; i++) {
        r.snapshotBettingVolume[betters[i]] = bettingVolumes[i];
        r.totalBettingVolume += bettingVolumes[i];
    }
}

function uploadReferrals(address[] calldata referrers, uint256[] calldata referralAmounts) external onlyOwner {
    require(currentRound > 0, "Deposit revenue first");
    Round storage r = rounds[currentRound];
    require(!r.isSnapshotUploaded, "Snapshot already uploaded for this round");

    for (uint256 i = 0; i < referrers.length; i++) {
        r.snapshotReferrals[referrers[i]] = referralAmounts[i];
        r.totalReferrals += referralAmounts[i];
    }
}

function lockSnapshot() external onlyOwner {
    require(currentRound > 0, "Deposit revenue first");
    Round storage r = rounds[currentRound];
    require(!r.isSnapshotUploaded, "Snapshot already uploaded for this round");

    r.isSnapshotUploaded = true;
}

   function claim(uint256 roundNumber) external {
    require(roundNumber > 0 && roundNumber <= currentRound, "Invalid round number");
    Round storage r = rounds[roundNumber];
    require(r.isSnapshotUploaded, "Snapshot not uploaded for this round");
    require(!r.hasClaimed[msg.sender], "You have already claimed for this round");

    uint256 totalClaim = 0;

    if (r.snapshotBBBalances[msg.sender] > 0) {
        totalClaim += (r.revenueForBB * r.snapshotBBBalances[msg.sender]) / r.totalBBTokens;
    }
    
    if (r.snapshotBettingVolume[msg.sender] > 0) {
        totalClaim += (r.revenueForBettingVolume * r.snapshotBettingVolume[msg.sender]) / r.totalBettingVolume;
    }
    
    if (r.snapshotReferrals[msg.sender] > 0) {
        totalClaim += (r.revenueForReferrals * r.snapshotReferrals[msg.sender]) / r.totalReferrals;
    }
    
    require(totalClaim > 0, "No amount available to claim");
    r.hasClaimed[msg.sender] = true;

    (bool success,) = msg.sender.call{value: totalClaim}("");
    require(success, "Claim transfer failed");

    emit EthClaim(msg.sender, totalClaim, roundNumber);
}


   function getClaimableAmount(address userAddress, uint256 roundNumber) external view returns (
    uint256 bbClaim,
    uint256 bettingVolumeClaim,
    uint256 referralClaim,
    uint256 totalClaim
) {
    require(roundNumber > 0 && roundNumber <= currentRound, "Invalid round number");
    Round storage r = rounds[roundNumber];
    require(r.isSnapshotUploaded, "Snapshot not uploaded for this round");

    if (r.snapshotBBBalances[userAddress] > 0) {
        bbClaim = (r.revenueForBB * r.snapshotBBBalances[userAddress]) / r.totalBBTokens;
    }
    
    if (r.snapshotBettingVolume[userAddress] > 0) {
        bettingVolumeClaim = (r.revenueForBettingVolume * r.snapshotBettingVolume[userAddress]) / r.totalBettingVolume;
    }
    
    if (r.snapshotReferrals[userAddress] > 0) {
        referralClaim = (r.revenueForReferrals * r.snapshotReferrals[userAddress]) / r.totalReferrals;
    }
    
    totalClaim = bbClaim + bettingVolumeClaim + referralClaim;

    return (bbClaim, bettingVolumeClaim, referralClaim, totalClaim);
}



    function setIncentivesAddress(address _newIncentivesAddress) external onlyOwner {
        incentivesAddress = _newIncentivesAddress;
    }

    function withdrawUnclaimed() public onlyOwner {
        require(currentRound > 0, "No rounds available for withdrawal");
        Round storage r = rounds[currentRound];
        
        uint256 unclaimedBB = r.revenueForBB;
        uint256 unclaimedBetting = r.revenueForBettingVolume;
        uint256 unclaimedReferrals = r.revenueForReferrals;
        
        r.revenueForBB = 0;
        r.revenueForBettingVolume = 0;
        r.revenueForReferrals = 0;
        
        (bool success,) = msg.sender.call{value: unclaimedBB + unclaimedBetting + unclaimedReferrals}("");
        require(success, "Withdraw failed");

        emit AdminWithdraw(unclaimedBB + unclaimedBetting + unclaimedReferrals, currentRound);
    }

    receive() external payable {
        revert("Send ETH using depositRevenue function");
    }
}