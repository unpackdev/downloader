// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Counters.sol";

import "./ERC20Permit.sol";

contract ImpactPayment is Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    
    uint public total_transactions = 0;
    Counters.Counter private _campaignIds;
    Counters.Counter private _campaignsCompleted;
    
    struct ImpactCampaign {
        uint256 id;
        address campaignOwner;
        string campaignName;
        string ownerName;
        bool complete;
    }

    struct Donation {
        address donor;
        uint256 donationAmount;
    }

    mapping(address => bool) public tokens_allowed;
    address private _baseTokenAddress;
    address private _wETH9Address;
    address private immutable swapRouter;
    uint24 private constant poolFee = 3000;
    uint32 private constant tickWindow = 100;
    
    mapping(address => uint256) public deposits; // total deposited funds for a user

    mapping(uint256 => mapping(address => uint256)) public campaignDeposits; // total deposited funds for a user
    mapping(uint256 => uint256) public campaignFunds; // total funds of a campaign
    mapping(uint256 => ImpactCampaign) public idToImpactCampaign; // impact campaigns that are launched
    mapping(address => uint256[]) public userToImpactCampaignIds;
    mapping(uint256 => address[]) public impactCampaignIdsToUsers;

    event CampaignCreated(uint256 indexed id, address campaignOwner, string campaignName, string ownerName);
    event Deposit(address indexed sender, uint256 amount, uint256 campaignId);
    event Withdraw(address indexed recipient, uint256 amount, uint256 campaignId);
    
    constructor(address[] memory tokenAddresses, address baseTokenAddress, address wETH9Address, address swapRouterAddress) {
        for(uint256 i = 0; i < tokenAddresses.length; i++) {
            tokens_allowed[tokenAddresses[i]] = true;
        }
        _baseTokenAddress = baseTokenAddress;
        _wETH9Address = wETH9Address;
        swapRouter = swapRouterAddress;
    }
    
    function getCampaignFunds(uint256 campaignId) public view returns (uint256) {
        return campaignFunds[campaignId];
    }

    function getUserTotalDeposits(address userAddress) public view returns (uint256) {
        return deposits[userAddress];
    }

    function getUserCampaignDeposits(uint256 campaignId, address userAddress) public view returns (uint256) {
        return campaignDeposits[campaignId][userAddress];
    }

    function getUserDonatedCampaigns(address userAddress) public view returns (ImpactCampaign[] memory) {
        uint256[] memory userDonatedCampaignIds = userToImpactCampaignIds[userAddress];
        ImpactCampaign[] memory userDonatedCampaigns = new ImpactCampaign[](userDonatedCampaignIds.length);
        for(uint256 i = 0; i < userDonatedCampaignIds.length; i++) {
            userDonatedCampaigns[i] = idToImpactCampaign[userDonatedCampaignIds[i]];
        }
        return userDonatedCampaigns;
    }

    function getUserDonationsToCampaign(uint256 campaignId) public view returns (Donation[] memory) {
        address[] memory usersThatDonatedToCampaign = impactCampaignIdsToUsers[campaignId];
        Donation[] memory userDonations = new Donation[](usersThatDonatedToCampaign.length);
        for (uint256 i = 0; i < usersThatDonatedToCampaign.length; i++) {
            userDonations[i] = Donation(
                usersThatDonatedToCampaign[i],
                campaignDeposits[campaignId][usersThatDonatedToCampaign[i]]
            );
        }
        return userDonations;
    }

    function getCampaigns() public view returns (ImpactCampaign[] memory) {
        uint256 campaignCount = _campaignIds.current();
        ImpactCampaign[] memory impactCampaigns = new ImpactCampaign[](campaignCount);
        for(uint256 i = 0; i < campaignCount; i++) {
            impactCampaigns[i] = idToImpactCampaign[i+1];
        }
        return impactCampaigns;
    }
    
    function getActiveCampaigns() public view returns (ImpactCampaign[] memory) {
        uint256 campaignCount = _campaignIds.current() - _campaignsCompleted.current();
        ImpactCampaign[] memory impactCampaigns = new ImpactCampaign[](campaignCount);
        for(uint256 i = 0; i < campaignCount; i++) {
            if (!idToImpactCampaign[i+1].complete) {
                impactCampaigns[i] = idToImpactCampaign[i+1];
            }
        }
        return impactCampaigns;
    }
    
    function getCompletedCampaigns() public view returns (ImpactCampaign[] memory) {
        uint256 campaignCount = _campaignsCompleted.current();
        ImpactCampaign[] memory impactCampaigns = new ImpactCampaign[](campaignCount);
        for(uint256 i = 0; i < campaignCount; i++) {
            if (idToImpactCampaign[i+1].complete) {
                impactCampaigns[i] = idToImpactCampaign[i+1];
            }
        }
        return impactCampaigns;
    }
    
    function createCampaign(address campaignOwner, string memory campaignName, string memory ownerName) public onlyOwner {
        _campaignIds.increment();
        uint256 campaignId = _campaignIds.current();
        idToImpactCampaign[campaignId] = ImpactCampaign(
            campaignId,
            campaignOwner,
            campaignName,
            ownerName,
            false
        );
        emit CampaignCreated(campaignId, campaignOwner, campaignName, ownerName);
    }

    function endCampaign(uint256 campaignId) public onlyOwner {
        require(campaignId < _campaignIds.current(), "Invalid campaign id");
        ImpactCampaign storage currCampaign = idToImpactCampaign[campaignId];
        currCampaign.complete = true;
        _campaignsCompleted.increment();
    }

    function withdrawFunds(uint256 campaignId, uint256 amount) public onlyOwner {
        require(ERC20(_baseTokenAddress).balanceOf(address(this)) >= amount,
                "There are not sufficient funds for this withdrawal");
        require(campaignFunds[campaignId] >= amount,
                "This campaign does not have sufficient funds for this withdrawal");
        address campaignOwner = idToImpactCampaign[campaignId].campaignOwner;
        ERC20(_baseTokenAddress).transfer(campaignOwner, amount);
        campaignFunds[campaignId] -= amount;
        emit Withdraw(campaignOwner, amount, campaignId);
    }

    function withdrawFundsETH(uint256 campaignId, uint256 amount) public onlyOwner {
        require(campaignFunds[campaignId] >= amount, 
                "This campaign does not have sufficient funds for this withdrawal");
        require(address(this).balance >= amount, 
                "This campaign does not have sufficient ETH for this withdrawal");
        address campaignOwner = idToImpactCampaign[campaignId].campaignOwner;
        payable(campaignOwner).transfer(amount);
        emit Withdraw(campaignOwner, amount, campaignId);
    }

    function depositFunds(address tokenAddress, uint256 amount, uint256 campaignId) public {
        require(tokens_allowed[tokenAddress], "We do not accept deposits of this ERC20 token");
        require(ERC20(tokenAddress).balanceOf(msg.sender) >= amount, 
                "You do not have sufficient funds to make this purchase");
        ERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        uint256 amountOut = amount;
        deposits[msg.sender] += amountOut;
        userToImpactCampaignIds[msg.sender].push(campaignId);
        impactCampaignIdsToUsers[campaignId].push(msg.sender);
        campaignDeposits[campaignId][msg.sender] += amountOut;
        campaignFunds[campaignId] += amountOut;
        total_transactions++;
        emit Deposit(msg.sender, amountOut, campaignId);
    }
    
    function depositFundsETH(uint256 campaignId) public payable {
        uint256 amountOut = msg.value;
        // amountOut = swapExactInputToBaseTokenSingle(_wETH9Address, msg.value);
        deposits[msg.sender] += amountOut;
        userToImpactCampaignIds[msg.sender].push(campaignId);
        impactCampaignIdsToUsers[campaignId].push(msg.sender);
        campaignDeposits[campaignId][msg.sender] += amountOut;
        campaignFunds[campaignId] += amountOut;
        total_transactions++;
        emit Deposit(msg.sender, amountOut, campaignId);
    }
    
    function allowTokenDeposits(address tokenAddress) public onlyOwner {
        tokens_allowed[tokenAddress] = true;
    }
}
