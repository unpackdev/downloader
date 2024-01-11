// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";

interface ERC721 {
    function getLastTransfer(uint256 _id) external view returns (uint256);
    function hasRedeemed(uint256 _id, uint256 i) external returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface BRICKS {
    function claim(address wallet, uint256 amount) external;
    function totalSupply(uint256 id) external view returns (uint256);
    function getMaxSupply() external view returns (uint256);
}

contract BricksLogic is Initializable, OwnableUpgradeable {
    
    BRICKS private bricks;
    ERC721 private nft;
    uint256 interval;
    uint256 mintAmount;
    mapping(uint256 => uint256) public price;
    mapping(uint256 => mapping(address => uint256)) public usersSupplyOfType;
    mapping(uint256 => mapping(uint256 => uint256)) private collected;

    struct Brick_Status {
        uint256 lastTransferTimestamp;
        uint256 collected;
        uint256 maxClaimableAmount;
        uint256 nftId;
    }

    function initialize() initializer public {
        __Ownable_init_unchained();

        // init stuff here please
        interval = 30 days;
        mintAmount = 1;
    }

    function setIntervalInSeconds(uint256 newInterval) public onlyOwner {
        interval = newInterval;
    }

    function getMaxMintableAmount(uint256 lastTransferTimestamp) internal view returns (uint256) {
        if (lastTransferTimestamp == 0) return 0;
        uint256 curr = block.timestamp;
        uint256 diff = curr - lastTransferTimestamp;
        uint256 currentInterval = diff / interval;
        return currentInterval;
    }

    function setContract(address nftContract) public onlyOwner {
        nft = ERC721(nftContract);
    }

    function setClaimAmount(uint256 claimAmt) external onlyOwner {
        mintAmount = claimAmt;
    }

    function setBricksContract(address newAddress) external onlyOwner {
        bricks = BRICKS(newAddress);
    }

    function distribute(address wallet, uint256 nftId) internal virtual returns (bool) {
        uint256 lastTransferTimestamp = nft.getLastTransfer(nftId);
        uint256 maxClaimableAmount = getMaxMintableAmount(lastTransferTimestamp);
        uint256 previouslyClaimed = collected[nftId][lastTransferTimestamp];
        require(previouslyClaimed < maxClaimableAmount, "None to claim yet");
        require(nft.ownerOf(nftId) == wallet, "That wallet does not own that NFT");
        uint256 claimable = (maxClaimableAmount - previouslyClaimed);
        if ((bricks.totalSupply(1) + (claimable * mintAmount)) > bricks.getMaxSupply()) {
            uint256 canClaim = (bricks.getMaxSupply() - bricks.totalSupply(1)) / mintAmount;
            if (canClaim > 0) {
                maxClaimableAmount = previouslyClaimed + canClaim;
                claimable = canClaim;
            } else {
                return false;
            }
        }
        bricks.claim(wallet, claimable * mintAmount);
        collected[nftId][lastTransferTimestamp] = maxClaimableAmount;
        return true;
    }

    function claim(address wallet, uint256 nftId) external virtual {
        bool res = distribute(wallet, nftId);
        require(res, "failed to claim bricks, there may be no more to claim.");
    }

    function claimBatch(address wallet, uint256[] memory nftIds) external virtual {
        uint256 count = nftIds.length;
        require(bricks.totalSupply(1) < bricks.getMaxSupply(), "All bricks are claimed");
        for(uint256 i = 0; i < count; i++) {
            distribute(wallet, nftIds[i]);
        }
    }

    function claimStatus(uint256 nftId) external view returns (uint256, uint256, uint256, uint256) {
        uint256 lastTransferTimestamp = nft.getLastTransfer(nftId);
        uint256 maxClaimableAmount = getMaxMintableAmount(lastTransferTimestamp);
        uint256 previouslyClaimed = collected[nftId][lastTransferTimestamp];
        return (lastTransferTimestamp, previouslyClaimed, maxClaimableAmount, (maxClaimableAmount - previouslyClaimed) * mintAmount);
    }

    function batchStatus(uint256[] memory nftIds) external view returns (Brick_Status[] memory) {
        uint256 total = nftIds.length;
        Brick_Status[] memory statuses = new Brick_Status[](total);
        for(uint256 i = 0; i < total; i++) {
            uint256 lastTransferTimestamp = nft.getLastTransfer(nftIds[i]);
            uint256 maxClaimableAmount = getMaxMintableAmount(lastTransferTimestamp);
            uint256 previouslyClaimed = collected[nftIds[i]][lastTransferTimestamp];
            statuses[i] = Brick_Status(lastTransferTimestamp, collected[nftIds[i]][lastTransferTimestamp], (maxClaimableAmount - previouslyClaimed) * mintAmount, nftIds[i]);
        }
        return statuses;
    }
}