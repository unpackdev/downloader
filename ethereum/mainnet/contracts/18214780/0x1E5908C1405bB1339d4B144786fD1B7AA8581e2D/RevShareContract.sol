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
        uint256 startTime;
        bool isSnapshotUploaded;
        mapping(address => uint256) snapshotBBBalances;
        mapping(address => uint256) snapshotBettingVolume;
        mapping(address => uint256) snapshotReferrals;
    }

    mapping(uint256 => Round) public rounds;

    // Separate mapping for each type of claim
    mapping(uint256 => mapping(address => bool)) hasClaimedBB;
    mapping(uint256 => mapping(address => bool)) hasClaimedBettingVolume;
    mapping(uint256 => mapping(address => bool)) hasClaimedReferral;

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

        rounds[currentRound].startTime = block.timestamp;
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

    function claimBB(uint256 roundNumber) external {
        // Checks
        require(roundNumber > 0 && roundNumber <= currentRound, "Invalid round number");
        Round storage r = rounds[roundNumber];
        require(r.isSnapshotUploaded, "Snapshot not uploaded for this round");
        require(!hasClaimedBB[roundNumber][msg.sender], "You have already claimed BB for this round");
        require(r.snapshotBBBalances[msg.sender] > 0, "No BB balance to claim");
        
        uint256 claimAmount = (r.revenueForBB * r.snapshotBBBalances[msg.sender]) / r.totalBBTokens;

        // Effects
        hasClaimedBB[roundNumber][msg.sender] = true;

        // Interactions
        (bool success,) = msg.sender.call{value: claimAmount}("");
        require(success, "Claim BB transfer failed");
        emit EthClaim(msg.sender, claimAmount, roundNumber);
    }

    function claimBettingVolume(uint256 roundNumber) external {
        // Checks
        require(roundNumber > 0 && roundNumber <= currentRound, "Invalid round number");
        Round storage r = rounds[roundNumber];
        require(r.isSnapshotUploaded, "Snapshot not uploaded for this round");
        require(!hasClaimedBettingVolume[roundNumber][msg.sender], "You have already claimed Betting Volume for this round");
        require(r.snapshotBettingVolume[msg.sender] > 0, "No Betting Volume to claim");

        uint256 claimAmount = (r.revenueForBettingVolume * r.snapshotBettingVolume[msg.sender]) / r.totalBettingVolume;

        // Effects
        hasClaimedBettingVolume[roundNumber][msg.sender] = true;

        // Interactions
        (bool success,) = msg.sender.call{value: claimAmount}("");
        require(success, "Claim Betting Volume transfer failed");
        emit EthClaim(msg.sender, claimAmount, roundNumber);
    }

    function claimReferral(uint256 roundNumber) external {
        // Checks
        require(roundNumber > 0 && roundNumber <= currentRound, "Invalid round number");
        Round storage r = rounds[roundNumber];
        require(r.isSnapshotUploaded, "Snapshot not uploaded for this round");
        require(!hasClaimedReferral[roundNumber][msg.sender], "You have already claimed Referrals for this round");
        require(r.snapshotReferrals[msg.sender] > 0, "No Referrals to claim");

        uint256 claimAmount = (r.revenueForReferrals * r.snapshotReferrals[msg.sender]) / r.totalReferrals;

        // Effects
        hasClaimedReferral[roundNumber][msg.sender] = true;

        // Interactions
        (bool success,) = msg.sender.call{value: claimAmount}("");
        require(success, "Claim Referral transfer failed");
        emit EthClaim(msg.sender, claimAmount, roundNumber);
    }

   function claimableBB(address userAddress, uint256 roundNumber) external view returns (uint256) {
    require(roundNumber > 0 && roundNumber <= currentRound, "Invalid round number");
    Round storage r = rounds[roundNumber];
    require(r.isSnapshotUploaded, "Snapshot not uploaded for this round");

    if (hasClaimedBB[roundNumber][userAddress]) {
        return 0;
    }

    if (r.snapshotBBBalances[userAddress] > 0) {
        return (r.revenueForBB * r.snapshotBBBalances[userAddress]) / r.totalBBTokens;
    }
    return 0;
}

function claimableBettingVolume(address userAddress, uint256 roundNumber) external view returns (uint256) {
    require(roundNumber > 0 && roundNumber <= currentRound, "Invalid round number");
    Round storage r = rounds[roundNumber];
    require(r.isSnapshotUploaded, "Snapshot not uploaded for this round");

    if (hasClaimedBettingVolume[roundNumber][userAddress]) {
        return 0;
    }

    if (r.snapshotBettingVolume[userAddress] > 0) {
        return (r.revenueForBettingVolume * r.snapshotBettingVolume[userAddress]) / r.totalBettingVolume;
    }
    return 0;
}

function claimableReferral(address userAddress, uint256 roundNumber) external view returns (uint256) {
    require(roundNumber > 0 && roundNumber <= currentRound, "Invalid round number");
    Round storage r = rounds[roundNumber];
    require(r.isSnapshotUploaded, "Snapshot not uploaded for this round");

    if (hasClaimedReferral[roundNumber][userAddress]) {
        return 0;
    }

    if (r.snapshotReferrals[userAddress] > 0) {
        return (r.revenueForReferrals * r.snapshotReferrals[userAddress]) / r.totalReferrals;
    }
    return 0;
}



    function setIncentivesAddress(address _newIncentivesAddress) external onlyOwner {
        incentivesAddress = _newIncentivesAddress;
    }

    function withdrawUnclaimed() public onlyOwner {
        require(currentRound > 0, "No rounds available for withdrawal");
        Round storage r = rounds[currentRound];
        require(block.timestamp >= r.startTime + 90 days, "Cannot withdraw before 90 days have passed");
        
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