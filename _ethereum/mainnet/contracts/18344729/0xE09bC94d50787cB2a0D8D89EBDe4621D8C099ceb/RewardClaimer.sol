// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./XZKitty.sol";

contract RewardClaimer is ReentrancyGuard, Ownable {
    XZKitty public nftContract;
    uint256 public minimumETHForNextEpoch;
    uint256 public currentEpoch;
    uint256 public totalRewardsCollected;
    uint256 public totalRewardsDistributed;
    // EPOCH -> REWARD
    mapping(uint256 => uint256) public rewardPerNFT;
    // EPOCH -> PARTICIPANTS
    mapping(uint256 => uint256) public participantsInEpoch;
    // EPOCH -> CLAIMS
    mapping(uint256 => uint256) public claimsInEpoch;
    mapping(uint256 => mapping(uint256 => bool)) public claimedRewards; // epoch -> tokenId -> claimed

    constructor(address _nftAddress, uint256 _minimumETHForNextEpoch) {
        nftContract = XZKitty(_nftAddress);
        minimumETHForNextEpoch = _minimumETHForNextEpoch;
    }

    function startNewEpoch() external {
        uint256 rewardsDuringEpochPeriod = address(this).balance -
            (totalRewardsCollected - totalRewardsDistributed);
        require(
            rewardsDuringEpochPeriod >= minimumETHForNextEpoch,
            "Insufficient ETH balance to start new epoch"
        );
        require(
            nftContract.totalSupply() > 0,
            "At least one NFT needs to be minted"
        );
        if (currentEpoch == 0) {
            participantsInEpoch[currentEpoch] = nftContract.totalSupply();
        }

        participantsInEpoch[currentEpoch + 1] = nftContract.totalSupply();

        totalRewardsCollected += rewardsDuringEpochPeriod;
        rewardPerNFT[currentEpoch] =
            rewardsDuringEpochPeriod /
            participantsInEpoch[currentEpoch];

        currentEpoch++;
    }

    // @param tokenIds It's a nested list that contains NFT'id in each epochs that rewards are claimed for
    // @param epochIds epochs that rewards are claimed for

    function claimRewards(
        uint256[][] calldata tokenIds,
        uint256[] calldata epochIds
    ) external nonReentrant {
        require(tokenIds.length == epochIds.length, "Mismatched arrays");
        uint256 totalPendingRewards;
        for (uint256 i = 0; i < epochIds.length; i++) {
            uint256 epochId = epochIds[i];
            uint256 NFTRewardCurrentEpoch = rewardPerNFT[epochId];
            for (uint256 j = 0; j < tokenIds[i].length; j++) {
                uint256 tokenId = tokenIds[i][j];

                require(
                    nftContract.ownerOf(tokenId) == msg.sender,
                    "Sender is not the owner of the NFT"
                );
                require(
                    tokenId < participantsInEpoch[epochId],
                    "ID not participating"
                );
                require(
                    !claimedRewards[epochId][tokenId],
                    "Reward for this epoch already claimed"
                );

                claimedRewards[epochId][tokenId] = true;
                totalPendingRewards += NFTRewardCurrentEpoch;
            }
            claimsInEpoch[epochId] += tokenIds[i].length;
        }
        totalRewardsDistributed += totalPendingRewards;
        (bool success, ) = payable(msg.sender).call{value: totalPendingRewards}(
            ""
        );
        require(success, "Transfer failed");
    }

    function getPendingRewards(
        uint256[][] calldata tokenIds,
        uint256[] calldata epochIds
    ) external view returns (uint256 totalRewards) {
        require(tokenIds.length == epochIds.length, "Mismatched arrays");
        for (uint256 i = 0; i < epochIds.length; i++) {
            uint256 epochId = epochIds[i];
            uint256 participants = participantsInEpoch[epochId];
            uint256 rewardsPerNFT = rewardPerNFT[epochId];
            for (uint256 j = 0; j < tokenIds[i].length; j++) {
                uint256 tokenId = tokenIds[i][j];
                require(tokenId < participants, "ID not participating");
                if (!claimedRewards[epochId][tokenId]) {
                    totalRewards += rewardsPerNFT;
                }
            }
        }
    }

    function withdrawETH(uint256 amount) external onlyOwner {
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Transfer failed");
    }

    function getParticipantsInEpochs(
        uint256[] calldata epochIds
    ) external view returns (uint256[] memory participants) {
        participants = new uint256[](epochIds.length);
        for (uint256 i = 0; i < epochIds.length; i++) {
            participants[i] = participantsInEpoch[epochIds[i]];
        }
    }

    function getClaimsInEpochs(
        uint256[] calldata epochIds
    ) external view returns (uint256[] memory claims) {
        claims = new uint256[](epochIds.length);
        for (uint256 i = 0; i < epochIds.length; i++) {
            claims[i] = claimsInEpoch[epochIds[i]];
        }
    }

    function getNFTsClaimStatusForEpochs(
        uint256[][] calldata tokenIds,
        uint256[] calldata epochIds
    ) external view returns (bool[][] memory) {
        require(tokenIds.length == epochIds.length, "Mismatched arrays");

        bool[][] memory claimStatus = new bool[][](epochIds.length);

        for (uint256 i = 0; i < epochIds.length; i++) {
            claimStatus[i] = new bool[](tokenIds[i].length);
            uint256 epoch = epochIds[i];

            for (uint256 j = 0; j < tokenIds[i].length; j++) {
                claimStatus[i][j] = claimedRewards[epoch][tokenIds[i][j]];
            }
        }

        return claimStatus;
    }

    function canStartNewEpoch() public view returns (bool) {
        uint256 rewardsDuringEpochPeriod = address(this).balance -
            (totalRewardsCollected - totalRewardsDistributed);

        if (rewardsDuringEpochPeriod < minimumETHForNextEpoch) {
            return false;
        }

        if (nftContract.totalSupply() == 0) {
            return false;
        }

        return true;
    }

    function rewardsAccumulatedTowardsNextEpoch()
        public
        view
        returns (uint256 rewardsDuringEpochPeriod)
    {
        return
            address(this).balance -
            (totalRewardsCollected - totalRewardsDistributed);
    }

    function setMinimumETHForNextEpoch(uint256 amount) external onlyOwner {
        minimumETHForNextEpoch = amount;
    }

    // Fallback function to accept incoming ETH
    receive() external payable {}
}
