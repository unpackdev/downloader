// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "./IERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract GYM is Ownable{
    IERC20 CHAD;
    IERC721 public CAGC;
    bool public paused = true;
    uint256 public rate = 10 ether;

    struct Staking {
        uint256 timestamp;
        address owner;
    }

    struct StakingInfo {
        uint256 tokenId;
        uint256 timestamp;
        uint256 rewards;
    }

    mapping(uint256 => Staking) public stakings;
    mapping(address => uint256[]) public stakingsByOwner;

    constructor(address _cagc, address _chad) {
        CAGC = IERC721(_cagc);
        CHAD = IERC20(_chad);
    }

    // Staking CHAD APE
    function stakeChadApe(uint256 tokenId) public {
        require(!paused, "Contract paused");
        require (msg.sender == CAGC.ownerOf(tokenId), "Sender must be the owner");
        require(CAGC.isApprovedForAll(msg.sender, address(this)));

        Staking memory staking = Staking(block.timestamp, msg.sender);
        stakings[tokenId] = staking;
        stakingsByOwner[msg.sender].push(tokenId);
        CAGC.transferFrom(msg.sender, address(this), tokenId);
    }

    // batch stake
    function batchStakeChadApe(uint256[] memory tokenIds) external {
        for (uint8 i = 0; i < tokenIds.length; i++) {
            stakeChadApe(tokenIds[i]);
        }
    }

    // claim rewards
    function claimRewards(uint256 tokenId, bool unstake) external {
        require(!paused, "Contract paused");
        uint256 rewards = _claim(tokenId);

        if (unstake) {
            unstakeChadApe(tokenId);
        }

        if (rewards > 0) {
            require(CHAD.transfer(msg.sender, rewards));
        }
    }

    // batch claim rewards
    function batchClaimRewards(uint256[] memory tokenIds, bool unstake) external {
        require(!paused, "Contract paused");

        uint256 netRewards = 0;
        for (uint8 i = 0; i < tokenIds.length; i++) {
            netRewards += _claim(tokenIds[i]);
        }

        if (netRewards > 0) {
            require(CHAD.transfer(msg.sender, netRewards));
        }

        if (unstake) {
            for (uint8 i = 0; i < tokenIds.length; i++) {
                unstakeChadApe(tokenIds[i]);
            }
        }
    }

    function _claim(uint256 tokenId) internal returns (uint256) {
        require(CAGC.ownerOf(tokenId) == address(this), "The Chad Ape must be staked");
        Staking storage staking = stakings[tokenId];
        require(staking.owner == msg.sender, "Sender must be the owner");

        uint256 rewards = calculateReward(tokenId);
        staking.timestamp = block.timestamp;

        return rewards;
    }

    // Un-staking
    function unstakeChadApe(uint256 tokenId) internal {
        Staking storage staking = stakings[tokenId];
        uint256[] storage stakedApes = stakingsByOwner[msg.sender];
        uint16 index = 0;
        for (; index < stakedApes.length; index++) {
            if (stakedApes[index] == tokenId) {
                break;
            }
        }
        require(index < stakedApes.length, "Chad Ape not found");
        stakedApes[index] = stakedApes[stakedApes.length - 1];
        stakedApes.pop();
        staking.owner = address(0);
        CAGC.transferFrom(address(this), msg.sender, tokenId);
    }

    // emergency Un-staking
    // remember user won't receive any rewards if the user use this method
    function emergencyUnstakeChadApe(uint256 tokenId) external {
        require(CAGC.ownerOf(tokenId) == address(this), "The Chad Ape must be staked");
        Staking storage staking = stakings[tokenId];
        require(staking.owner == msg.sender, "Sender must be the owner");
        uint256[] storage stakedApes = stakingsByOwner[msg.sender];
        uint16 index = 0;
        for (; index < stakedApes.length; index++) {
            if (stakedApes[index] == tokenId) {
                break;
            }
        }
        require(index < stakedApes.length, "Chad Ape not found");
        stakedApes[index] = stakedApes[stakedApes.length - 1];
        stakedApes.pop();
        staking.owner = address(0);
        CAGC.transferFrom(address(this), msg.sender, tokenId);
    }

    // Get staking info by user
    function stakingInfo(address owner) public view returns (StakingInfo[] memory) {
        uint256 balance = stakedBalanceOf(owner);
        StakingInfo[] memory list = new StakingInfo[](balance);

        for (uint16 i = 0; i < balance; i++) {
            uint256 tokenId = stakingsByOwner[owner][i];
            Staking memory staking = stakings[tokenId];
            uint256 reward = calculateReward(tokenId);
            list[i] = StakingInfo(tokenId, staking.timestamp, reward);
        }

        return list;
    }

    function calculateReward(uint256 tokenId) public view returns (uint256) {
        require(CAGC.ownerOf(tokenId) == address(this), "The Chad Ape must be staked");
        uint256 balance = CHAD.balanceOf(address(this));
        Staking storage staking = stakings[tokenId];
        uint256 diff = block.timestamp - staking.timestamp;
        uint256 dayCount = uint256(diff) / (1 days);
        if (dayCount < 1 || balance == 0) {
            return 0;
        }
        return dayCount * rate;
    }

    function togglePause() external onlyOwner {
        paused = !paused;
    }

    function stakedBalanceOf(address owner) public view returns (uint256) {
        return stakingsByOwner[owner].length;
    }
}