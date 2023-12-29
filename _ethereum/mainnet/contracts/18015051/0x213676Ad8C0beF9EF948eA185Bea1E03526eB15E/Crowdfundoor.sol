// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

//
//                            _  __                 _
//                           | |/ _|               | |
//   ___ _ __ _____      ____| | |_ _   _ _ __   __| | ___   ___  _ __
//  / __| '__/ _ \ \ /\ / / _` |  _| | | | '_ \ / _` |/ _ \ / _ \| '__|
// | (__| | | (_) \ V  V / (_| | | | |_| | | | | (_| | (_) | (_) | |
//  \___|_|  \___/ \_/\_/ \__,_|_|  \__,_|_| |_|\__,_|\___/ \___/|_|
//
//                                                 by netdragonx.eth
//
import "./IERC721.sol";

struct Campaign {
    uint256 amount;
    uint256 tokenId;
    address tokenAddress;
    address recipient;
    bool isAccepted;
    mapping(address => uint256) donations;
}

contract Crowdfundoor {
    mapping(uint256 => Campaign) public campaigns;
    uint256 public nextCampaignId;

    error AlreadyOwned();
    error AmountLessThanMinimum();
    error DonationRequired();
    error InvalidRecipient();
    error NoDonationToWithdraw();
    error NotTokenOwner();
    error TransferFailed();
    error CampaignAlreadyAccepted();

    event Start(uint256 indexed campaignId, address indexed tokenAddress, uint256 indexed tokenId, address recipient);
    event Donation(uint256 indexed campaignId, address indexed donor, uint256 amount);
    event Withdrawal(uint256 indexed campaignId, address indexed donor, uint256 amount);
    event Accepted(uint256 indexed campaignId);

    function startCampaign(address tokenAddress, uint256 tokenId, address recipient) external returns (uint256) {
        if (IERC721(tokenAddress).ownerOf(tokenId) == recipient) {
            revert AlreadyOwned();
        }

        uint256 campaignId = nextCampaignId;

        Campaign storage newCampaign = campaigns[campaignId];
        newCampaign.tokenAddress = tokenAddress;
        newCampaign.tokenId = tokenId;
        newCampaign.recipient = recipient;

        unchecked {
            nextCampaignId++;
        }

        emit Start(campaignId, tokenAddress, tokenId, recipient);

        return campaignId;
    }

    function donate(uint256 campaignId) external payable {
        if (msg.value == 0) {
            revert DonationRequired();
        }

        Campaign storage campaign = campaigns[campaignId];

        if (campaign.isAccepted) {
            revert CampaignAlreadyAccepted();
        }

        campaign.amount += msg.value;
        campaign.donations[msg.sender] += msg.value;

        emit Donation(campaignId, msg.sender, msg.value);
    }

    function accept(uint256 campaignId, uint256 minimumAmount) external {
        Campaign storage campaign = campaigns[campaignId];

        if (campaign.amount < minimumAmount) {
            revert AmountLessThanMinimum();
        }

        if (IERC721(campaign.tokenAddress).ownerOf(campaign.tokenId) != msg.sender) {
            revert NotTokenOwner();
        }

        uint256 amount = campaign.amount;
        campaign.amount = 0;
        campaign.isAccepted = true;

        IERC721(campaign.tokenAddress).transferFrom(msg.sender, campaign.recipient, campaign.tokenId);

        (bool success,) = payable(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed();

        emit Accepted(campaignId);
    }

    function withdraw(uint256 campaignId) external {
        Campaign storage campaign = campaigns[campaignId];

        if (campaign.isAccepted) {
            revert CampaignAlreadyAccepted();
        }

        uint256 donation = campaign.donations[msg.sender];
        if (donation == 0) {
            revert NoDonationToWithdraw();
        }

        campaign.donations[msg.sender] = 0;
        campaign.amount -= donation;

        (bool success,) = payable(msg.sender).call{value: donation}("");
        if (!success) revert TransferFailed();

        emit Withdrawal(campaignId, msg.sender, donation);
    }
}
