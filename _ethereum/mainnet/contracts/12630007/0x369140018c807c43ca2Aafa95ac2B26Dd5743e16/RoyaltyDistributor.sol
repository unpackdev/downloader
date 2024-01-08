// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./iRoyaltyDistributor.sol";
import "./IsekaiImoutoCampaignToken.sol";

contract RoyaltyDistributor is iRoyaltyDistributor, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    address payable[3] private recipients;
    uint256[3] private royalties = [40, 40, 10]; // and 10% for community
    uint256 private addressesAllocation;
    uint256 private communityAllocation;
    bool private isAllContentTokenBurned;

    IsekaiImoutoCampaignToken private campaignToken;

    constructor(
        address _campaignToken,
        address payable[3] memory _recipients
    ) {
        require(_campaignToken != address(0), "Invalid address");

        for (uint256 i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0), "Address must be non-zero");
        }

        recipients = _recipients;
        campaignToken = IsekaiImoutoCampaignToken(_campaignToken);
    }

    function updateRecipients(address payable[3] memory _recipients) external override onlyOwner {
        recipients = _recipients;
    }

    function withdrawETH() external override nonReentrant {
        updateAllocations();

        for (uint256 i = 0; i < recipients.length; i++) {
            Address.sendValue(recipients[i], addressesAllocation.mul(royalties[i]).div(90));
        }
        addressesAllocation = 0;
    }

    function withdrawableETH()
    external
    view
    override
    returns (uint256[] memory amounts)
    {
        uint256 balance = address(this).balance;
        uint256 balanceDiff = balance.sub((addressesAllocation.add(communityAllocation)));
        uint256 _addressesAllocation;
        if (isAllContentTokenBurned) {
            _addressesAllocation = addressesAllocation.add(balanceDiff);
        } else {
            _addressesAllocation = addressesAllocation.add((balanceDiff.mul(90).div(100)));
        }

        amounts = new uint256[](3);
        for (uint256 i = 0; i < recipients.length; i++) {
            amounts[i] = _addressesAllocation.mul(royalties[i]).div(90);
        }
    }

    function withdrawERC20(address token) external override {
        uint256 balance = ERC20(token).balanceOf(address(this));
        for (uint256 i = 0; i < recipients.length; i++) {
            ERC20(token).transfer(recipients[i], balance.mul(royalties[i]).div(90));
        }
    }

    function withdrawableERC20(address token) external view override returns (uint256[] memory amounts) {
        uint256 balance = ERC20(token).balanceOf(address(this));

        amounts = new uint256[](3);
        for (uint256 i = 0; i < recipients.length; i++) {
            amounts[i] = balance.mul(royalties[i]).div(90);
        }
    }

    function withdrawCommunityRoyalty(
        uint256 allowance
    ) external override nonReentrant {
        updateAllocations();

        uint256 allocation = communityAllocation.mul(allowance).div(campaignToken.totalSupply());
        communityAllocation = communityAllocation.sub(allocation);

        campaignToken.burnFrom(msg.sender, allowance);
        Address.sendValue(payable(msg.sender), allocation);
    }

    function withdrawableCommunityRoyalty(
        uint256 allowance
    ) external view override returns (uint256) {
        uint256 balance = address(this).balance;
        uint256 balanceDiff = balance.sub(addressesAllocation.add(communityAllocation));
        uint256 _communityAllocation = communityAllocation.add(
            balanceDiff.div(10) // * 10 / 100 
        );

        uint256 totalSupply = campaignToken.totalSupply();
        require(allowance <= totalSupply, "Exceed total supply");
        return _communityAllocation.mul(allowance).div(campaignToken.totalSupply());
    }

    function rescueCommunityToken() external {
        require(!isAllContentTokenBurned, "Already rescued");
        require(campaignToken.totalSupply() == 0, "All content token must be burned");

        isAllContentTokenBurned = true;
        addressesAllocation = addressesAllocation.add(communityAllocation);
        communityAllocation = 0;
    }

    function updateAllocations() private {
        uint256 balance = address(this).balance;
        uint256 balanceDiff = balance.sub(addressesAllocation.add(communityAllocation));

        if (balanceDiff == 0) {
            return;
        }
        if (isAllContentTokenBurned) {
            addressesAllocation = addressesAllocation.add(balanceDiff);
        } else {
            addressesAllocation = addressesAllocation.add(balanceDiff.mul(90).div(100));
            communityAllocation = communityAllocation.add(balanceDiff.mul(10).div(100));
        }
    }

    receive() external payable {}
}
