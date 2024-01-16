// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./MerkleProof.sol";

contract FlashBat is Ownable {
    bool public subscribingActive;
    bool public whitelistActive;
    uint256 public subscriptionPrice;
    uint256 public subscriptionLength;
    uint256 public whitelistDiscount;
    uint256 public whitelistPeriods;

    // Merkle Proof hash
    bytes32 public rootHash;

    // Mapping from address to subscription end time in seconds
    mapping(address => uint256) public subscriptionEnd;

    // Mapping from number of periods to discount in percent
    mapping(uint256 => uint256) public discounts;

    // Mapping to see if an address has subscribed at a discount before
    mapping(address => bool) private whitelistedSubscriberHasPurchased;

    constructor(
        uint256 _subscriptionPrice,
        uint256 _subscriptionLength,
        uint256 _whitelistDiscount,
        uint256 _whitelistPeriods,
        bool _subscribingActive,
        bool _whitelistActive
    ) {
        subscriptionPrice = _subscriptionPrice;
        subscriptionLength = _subscriptionLength;
        whitelistDiscount = _whitelistDiscount;
        whitelistPeriods = _whitelistPeriods;
        subscribingActive = _subscribingActive;
        whitelistActive = _whitelistActive;
    }

    // @notice Set the Merkle Tree root
    // @param _rootHash New root hash
    function setMerkleHash(bytes32 _rootHash) external onlyOwner {
        rootHash = _rootHash;
    }

    // @notice Set the subscription time length (in seconds)
    // @param _subscriptionLength Length of a subscription period (in seconds)
    function setSubscriptionLength(uint256 _subscriptionLength) external onlyOwner {
        subscriptionLength = _subscriptionLength;
    }

    // @notice Set the subscription price (in Wei)
    // @param _subscriptionPrice Amount to be paid for a subscription period (in Wei)
    function setSubscriptionPrice(uint256 _subscriptionPrice) external onlyOwner {
        subscriptionPrice = _subscriptionPrice;
    }

    // @notice Set a discount depending on number of periods bought
    // @param _periods Number of periods for which the discount will apply for
    // @param _discounts Discount values (in percent)
    function setDiscounts(uint256[] memory _periods, uint256[] memory _discounts) external onlyOwner {
        for (uint256 i = 0; i < _periods.length; i++) {
            discounts[_periods[i]] = _discounts[i];
        }
    }

    // @notice Set the whitelist discount value (in percent)
    // @param _whitelistDiscount New whitelist discount value (in percent)
    function setWhitelistDiscount(uint256 _whitelistDiscount) external onlyOwner {
        whitelistDiscount = _whitelistDiscount;
    }

    // @notice Set the number of periods for whitelisted members
    // @param _whitelistPeriods New number of periods for whitelisted members
    function setWhitelistPeriods(uint256 _whitelistPeriods) external onlyOwner {
        whitelistPeriods = _whitelistPeriods;
    }

    // @notice Enable or disable purchase of new subscriptions
    function setSubscribingActive() external onlyOwner {
        subscribingActive = !subscribingActive;
    }

    // @notice Enable or disable purchase of new whitelisted subscriptions
    function setWhitelistActive() external onlyOwner {
        whitelistActive = !whitelistActive;
    }

    // @notice Check if an address is currently subscribed
    // @param _address Address to check if currently subscribed
    function isSubscribed(address _address) public view returns (bool) {
        return block.timestamp <= subscriptionEnd[_address];
    }

    // @notice Get remaining time left regarding a subscription (in seconds)
    // @param _address Address to check remaining time for
    function getRemainingTime(address _address) external view returns (uint256) {

        // If not currently subscribed return zero
        uint256 remainingTime = 0;
        if (isSubscribed(_address)) {
            remainingTime = subscriptionEnd[_address] - block.timestamp;
        }

        return remainingTime;
    }

    // @notice Renew a subscription for 1 subscription period with no discount
    // @dev Acts as a function call with default value 1 for parameter periods
    function renewSubscription() external payable {
        renewSubscription(1);
    }

    // @notice Renew a subscription with no discount
    // @param periods Amount of time periods for which to renew the subscription for
    function renewSubscription(uint256 periods) public payable {
        renewSubscription(periods, discounts[periods]);
    }

    // @notice Owner can grant subscriptions to users
    // @param _address Addresses to grant a subscription for
    // @param _timestamps Timestamp until which subscription should be active for the given address
    function grantSubscription(address[] memory _addresses, uint256[] memory _timestamps) external onlyOwner {
        for (uint8 i = 0; i < _addresses.length; i++) {
            subscriptionEnd[_addresses[i]] = _timestamps[i];
        }
    }

    // @notice Get a discounted whitelist subscription
    // @param proof Merkle Tree proof
    function getWhitelistSubscription(bytes32[] memory proof) external payable {
        require(whitelistActive, "Whitelist purchasing is disabled");
        require(whitelistedSubscriberHasPurchased[msg.sender] == false, "You've already purchased");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, rootHash, leaf), "Invalid proof");

        whitelistedSubscriberHasPurchased[msg.sender] = true;

        renewSubscription(whitelistPeriods, whitelistDiscount);
    }

    // @notice Renew a subscription
    // @param periods Amount of time periods for which to renew the subscription for
    // @param _discount Discount amount (in percent)
    function renewSubscription(uint256 periods, uint256 _discount) internal {
        require(subscribingActive, "Purchase of new subscriptions is disabled");

        uint256 cost = (subscriptionPrice * periods * (100 - _discount)) / 100;
        require(msg.value == cost, "Incorrect payment amount");

        // Get maximum of current time and current subscription end time
        uint256 subscriptionStart = subscriptionEnd[msg.sender] >= block.timestamp ? subscriptionEnd[msg.sender] : block.timestamp;

        subscriptionEnd[msg.sender] = subscriptionStart + (subscriptionLength * periods);
    }
    
    // @notice Transfer remaining subscription time to a different address
    // @param to Address to which the remaining subscription time will be given
    function transferRemainingSubscription(address to) external {
        require(msg.sender == tx.origin, "No contracts allowed");
        require(isSubscribed(msg.sender), "Cannot transfer inactive subscription");

        uint256 remainingTime = subscriptionEnd[msg.sender] - block.timestamp;
        if(isSubscribed(to)) {
            subscriptionEnd[to] += remainingTime;
        }
        else {
            subscriptionEnd[to] = block.timestamp + remainingTime;
        }
        subscriptionEnd[msg.sender] = block.timestamp;
    }

    // @notice Withdraw Ether
    function withdrawEther() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}