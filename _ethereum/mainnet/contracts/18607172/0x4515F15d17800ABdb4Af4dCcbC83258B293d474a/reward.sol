// SPDX-License-Identifier: OSL-3.0	
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract Rewards {

   
    address public owner;
    IERC20 public incToken;

    struct Campaign {
        string title;
        uint256 prizePool;
        uint256 startTime;
        uint256 endTime;
        bool active;
        uint256 totalImpact;
    }

    struct Participant {
        uint256 impact;
        uint256 rewards;
    }

    // Events
    event CampaignCreated(uint256 indexed campaignId, address indexed creator);
    event UserRewarded(address indexed user, uint256 indexed campaignId, uint256 rewards);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyActiveCampaigns(uint256 campaignId) {
        require(campaigns[campaignId].active, "Campaign is not active");
        _;
    }

    // Mappings
    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => mapping(address => Participant)) public participants;
    uint256 public campaignCounter;

    // Constructor
    constructor(address _incToken) {
        owner = msg.sender;
        incToken = IERC20(_incToken);
    }

    function createCampaign(string memory _title, uint256 _prizePool, uint256 _duration) external onlyOwner {
        require(incToken.balanceOf(msg.sender) >= _prizePool, "Insufficient INC balance");
        incToken.transferFrom(msg.sender, address(this), _prizePool);

        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + _duration;

        campaigns[campaignCounter] = Campaign(_title, _prizePool, startTime, endTime, true, 0);
        emit CampaignCreated(campaignCounter, msg.sender);

        campaignCounter = campaignCounter + 1;
    }

    function participateInCampaign(uint256 campaignId, string memory content) external onlyActiveCampaigns(campaignId) {
        
        uint256 quality = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, content))) % 100;

        updateImpact(campaignId, msg.sender, quality);
    }

    function updateImpact(uint256 campaignId, address user, uint256 impact) internal onlyActiveCampaigns(campaignId) {
        participants[campaignId][user].impact = participants[campaignId][user].impact + impact;
        campaigns[campaignId].totalImpact = campaigns[campaignId].totalImpact + impact;
    }

    function rewardUser(uint256 campaignId, address user) external onlyOwner onlyActiveCampaigns(campaignId) {
        uint256 impact = participants[campaignId][user].impact;
        uint256 rewards = calculateReward(campaignId, impact);

        incToken.transfer(user, rewards);
        participants[campaignId][user].rewards = rewards;
        emit UserRewarded(user, campaignId, rewards);
    }

    function calculateReward(uint256 campaignId, uint256 impact) public view returns (uint256) {
        uint256 prizePool = campaigns[campaignId].prizePool;
        uint256 totalImpact = campaigns[campaignId].totalImpact;

       
        uint256 reward = (prizePool * impact) / totalImpact;
        return reward;
    }
}