// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract RevenueDistributor is Ownable, ReentrancyGuard {
    address public manager;
    uint256 public distributedEth;
    uint256 public lastDistributionTimestamp;
    struct UserDetails {
        address user;
        uint256 reward;
    }

    mapping(address => UserDetails) public rewardClaimable;
    mapping(address => bool) private isBlacklist;

    modifier onlyManager() {
        require(msg.sender == manager, "Not manager");
        _;
    }

    constructor(address _manager) {
        require(_manager != address(0), "Invalid address");
        manager = _manager;
        distributedEth = 0;
    }

    receive() external payable {
    }

    function setManagerAddress(address _manager) external onlyOwner {
        require(_manager != address(0), "Invalid address");
        manager = _manager;
    }

    function getLastDistributionTime() external view returns (uint256) {
        return lastDistributionTimestamp;
    }

    function blacklist(address[] memory a, bool status) external onlyManager {
        for (uint256 i = 0; i < a.length; i++) {
            isBlacklist[a[i]] = status;
        }
    }

    function distribute(
        UserDetails[] calldata _userDetails
    ) external onlyManager {
        for (uint256 i = 0; i < _userDetails.length; i++) {
            require(!isBlacklist[_userDetails[i].user]);
            uint256 userClaimAmount = _userDetails[i].reward;
            rewardClaimable[_userDetails[i].user].user = _userDetails[i].user;
            rewardClaimable[_userDetails[i].user].reward += userClaimAmount;
            distributedEth += userClaimAmount;
        }
        lastDistributionTimestamp = block.timestamp;
    }

    function claim() external nonReentrant {
        uint256 userClaimAmount = rewardClaimable[msg.sender].reward;
        require(userClaimAmount > 0, "Nothing to claim");
        require(address(this).balance >= userClaimAmount, "Insufficient funds");

        (bool sent, ) = payable(msg.sender).call{value: userClaimAmount}("");
        require(sent, "Failed to send Ether");
        rewardClaimable[msg.sender].reward = 0;
    }

    function pendingRewards(address account) external view returns (uint256) {
        return rewardClaimable[account].reward;
    }

    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficient funds");
        (bool sent, ) = payable(msg.sender).call{value: balance}("");
        require(sent, "Failed to send Ether");
    }
}
