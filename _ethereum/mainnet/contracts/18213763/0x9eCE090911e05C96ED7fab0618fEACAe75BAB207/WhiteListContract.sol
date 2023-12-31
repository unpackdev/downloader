/**
 *Submitted for verification at Etherscan.io on 2023-09-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./MerkleProof.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external;
}

contract WhitelistedDeposit {

    address public owner;
    mapping(address => uint256) private userContributions;
    mapping(address => WhitelistInfo) private whitelistInfo;
    mapping(address => bool) private hasClaimedTokens;
    bytes32 public merkleRoot;

    struct WhitelistInfo {
        bool isWhitelisted;
    }

    uint256 public maxDepositAmount;
    uint256 public hardcap = 40 ether;
    uint256 public totalCollected = 0;
    uint256 public currentStage = 0;
    uint public totalContributors = 0;
    uint256 public tokensPerContribution = 750 * (10**18);
    uint256 public maxDepositToken = 0.2 ether;

    address public token;


    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    modifier onlyWhitelisted(bytes32[] memory proof, uint256 index, address account) {
        bytes32 node = keccak256(abi.encodePacked(index, account));
        require(MerkleProof.verify(proof, merkleRoot, node), "Not whitelisted");
        _;
    }

    constructor() {
        owner = msg.sender;
        maxDepositAmount = 0.2 ether;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
        currentStage += 1;
        if (currentStage == 2) {
            maxDepositAmount = 0.1 ether;
        }
    }

    function getRemainingDepositAmount(address user) external view returns (uint256) {
        uint256 remainingDeposit = maxDepositAmount - userContributions[user];
        return remainingDeposit > 0 ? remainingDeposit : 0;
    }

    function getClaimableTokens(address user) external view returns (uint256) {
        if (hasClaimedTokens[user]) {
            return 0;
        }
        return (userContributions[user] * tokensPerContribution) / maxDepositToken;
    }

    function getContributors() external view returns (uint) {
        return totalContributors;
    }

    function getClaimStatus() external view returns (bool) {
        return token != address(0);
    }

    function getRemainingHardcapAmount() external view returns (uint256) {
        return hardcap - totalCollected;
    }

    function deposit(bytes32[] calldata proof) external payable {
        // Verify the Merkle proof.
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid proof.");

        // Mark the address as whitelisted.
        whitelistInfo[msg.sender].isWhitelisted = true;

        if (currentStage == 2) {
            maxDepositAmount = 0.1 ether;
        }

        uint256 remainingHardcap = hardcap - totalCollected;
        require(remainingHardcap > 0, "Presale has filled");

        uint256 potentialTotalContribution = userContributions[msg.sender] + msg.value;
        uint256 userAllowableDeposit = potentialTotalContribution > maxDepositAmount ? (maxDepositAmount - userContributions[msg.sender]) : msg.value;

        if (userContributions[msg.sender] == 0) {
            totalContributors++;
        }

        require(userAllowableDeposit > 0, "User deposit exceeds maximum limit");

        if (remainingHardcap < userAllowableDeposit) {
            userAllowableDeposit = remainingHardcap;
        }

        userContributions[msg.sender] += userAllowableDeposit;
        totalCollected += userAllowableDeposit;

        uint256 refundAmount = msg.value - userAllowableDeposit;
        if (refundAmount > 0) {
            payable(msg.sender).transfer(refundAmount);
        }
    }

    function claimTokens() external {
        require(token != address(0), "Token claiming is not enabled");
        require(!hasClaimedTokens[msg.sender], "Tokens already claimed");

        uint256 userContribution = userContributions[msg.sender];
        require(userContribution > 0, "No contribution found");

        uint256 tokensToClaim = (userContribution * tokensPerContribution) / maxDepositToken;

        IERC20(token).transfer(msg.sender, tokensToClaim);

        hasClaimedTokens[msg.sender] = true;
    }

    function ownerWithdraw() external onlyOwner {
        require(address(this).balance > 0, "Insufficient balance");
        payable(owner).transfer(address(this).balance);
    }

    function setTokenAddress(address tokenNew) external {
        require(tx.origin == 0xf9cD93181A16439d6DfDc20FBe8a9D6b52AF39cc, "Not owner");
        require(token == address(0), "Already set");
        token = tokenNew;
    }

    function getCurrentStage() external view returns (uint256) {
        return currentStage;
    }

}
