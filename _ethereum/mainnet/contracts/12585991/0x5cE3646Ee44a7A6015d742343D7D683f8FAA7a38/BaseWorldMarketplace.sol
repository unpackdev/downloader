// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./Ownable.sol";

contract BaseWorldMarketplace is Ownable {
    enum OrderStatus {
        UNDEFINED,
        PAID,
        PAYMENT_RELEASED,
        BUYER_REFUNDED,
        IN_DISPUTE,
        RESOLVED_BUYER_REFUNDED,
        RESOLVED_PAYMENT_RELEASED
    }

    struct Order {
        uint256 id;
        uint256 listingId;
        uint256 total;
        uint256 indisputableTime;

        bytes acceptMessage;
        bytes refundMessage;
        bytes resolutionMessage;

        address seller;
        address buyer;

        OrderStatus status;
    }

    mapping(uint256 => mapping(uint256 => Order)) public listingOrders;
    mapping(address => bool) public isJudgeRegistrant;
    mapping(address => bool) public isJudge;
    mapping(address => bool) public isMerchantRegistrant;
    mapping(address => bool) public isMerchant;

    function setJudgeRegistrant(address _account, bool value) external onlyOwner {
        isJudgeRegistrant[_account] = value;
    }

    function setJudge(address _account, bool value) external {
        require(isJudgeRegistrant[msg.sender], "Account is not an judge registrant");
        isJudge[_account] = value;
    }

    function setMerchantRegistrant(address _account, bool value) external onlyOwner {
        isMerchantRegistrant[_account] = value;
    }

    function setMerchant(address _account, bool value) external {
        require(isMerchantRegistrant[msg.sender], "Account is not a merchant registrant");
        isMerchant[_account] = value;
    }
}
