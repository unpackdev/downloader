// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";

/**
 * @title KaspaNodes Rental Contract
 * @dev This contract enables users to rent different types of KaspaNodes in exchange for KASNODE tokens.
 * Each node type has a specific rental price, payout amount, and rental period.
 * Users can claim their payout at the end of the rental period.
 * The contract owner can update node parameters and recover ERC20 tokens sent by mistake.
 */
contract NodeRental is Ownable {
    IERC20 public kasnodeToken;
    uint256 public constant TOTAL_SUPPLY = 28700000000 * (10 ** 18);

    struct Node {
        uint256 rentalPrice;
        uint256 payoutAmount;
        uint256 rentalPeriod;
        string nodeType;
    }

    Node public rapidNode;
    Node public ghostNode;
    Node public heavyNode;

    mapping(address => Node) public rentedNodes;
    mapping(address => uint256) public rentalStartTime;

    event NodeRented(address indexed renter, string nodeType, uint256 amount);
    event PayoutClaimed(address indexed renter, string nodeType, uint256 amount);

    bool public emergencyStopped = false;

    modifier stopInEmergency {
        require(!emergencyStopped, "Contract is stopped in an emergency");
        _;
    }

    constructor(address _kasnodeTokenAddress) Ownable(msg.sender) {
        kasnodeToken = IERC20(_kasnodeTokenAddress);
        rapidNode = Node(TOTAL_SUPPLY / 1000, 50 * (10 ** 18), 30 days, "RapidNode");
        ghostNode = Node(TOTAL_SUPPLY / 100, 500 * (10 ** 18), 90 days, "GhostNode");
        heavyNode = Node(TOTAL_SUPPLY / 20, 2500 * (10 ** 18), 180 days, "HeavyNode");
    }

    function rentRapidNode() external stopInEmergency {
        rentNode(rapidNode);
    }

    function rentGhostNode() external stopInEmergency {
        rentNode(ghostNode);
    }

    function rentHeavyNode() external stopInEmergency {
        rentNode(heavyNode);
    }

    function rentNode(Node memory node) internal {
        uint256 allowance = kasnodeToken.allowance(msg.sender, address(this));
        require(allowance >= node.rentalPrice, "Insufficient token allowance for node rental.");
        require(rentalStartTime[msg.sender] == 0 || rentalStartTime[msg.sender] + rentedNodes[msg.sender].rentalPeriod < block.timestamp, "Current node rental is still active or not yet started.");

        kasnodeToken.transferFrom(msg.sender, owner(), node.rentalPrice);
        rentedNodes[msg.sender] = node;
        rentalStartTime[msg.sender] = block.timestamp;

        emit NodeRented(msg.sender, node.nodeType, node.rentalPrice);
    }

    function claimPayout() external stopInEmergency {
        Node memory userNode = rentedNodes[msg.sender];
        require(userNode.rentalPrice > 0, "You have not rented a node.");
        require(rentalStartTime[msg.sender] + userNode.rentalPeriod <= block.timestamp, "Node rental period has not yet ended.");

        uint256 payoutAmount = userNode.payoutAmount;
        require(payoutAmount > 0, "No payout available.");
        require(kasnodeToken.balanceOf(address(this)) >= payoutAmount, "Insufficient funds in the contract for payout.");

        kasnodeToken.transfer(msg.sender, payoutAmount);
        rentalStartTime[msg.sender] = 0;

        emit PayoutClaimed(msg.sender, userNode.nodeType, payoutAmount);
    }

    function updateNodeParameters(string memory nodeType, uint256 rentalPrice, uint256 payoutAmount, uint256 rentalPeriod) external onlyOwner {
        if (keccak256(bytes(nodeType)) == keccak256(bytes("RapidNode"))) {
            rapidNode.rentalPrice = rentalPrice;
            rapidNode.payoutAmount = payoutAmount;
            rapidNode.rentalPeriod = rentalPeriod;
        } else if (keccak256(bytes(nodeType)) == keccak256(bytes("GhostNode"))) {
            ghostNode.rentalPrice = rentalPrice;
            ghostNode.payoutAmount = payoutAmount;
            ghostNode.rentalPeriod = rentalPeriod;
        } else if (keccak256(bytes(nodeType)) == keccak256(bytes("HeavyNode"))) {
            heavyNode.rentalPrice = rentalPrice;
            heavyNode.payoutAmount = payoutAmount;
            heavyNode.rentalPeriod = rentalPeriod;
        }
    }

    function toggleEmergencyStop() external onlyOwner {
        emergencyStopped = !emergencyStopped;
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAddress != address(kasnodeToken), "Cannot recover KASNODE tokens");
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }
}
