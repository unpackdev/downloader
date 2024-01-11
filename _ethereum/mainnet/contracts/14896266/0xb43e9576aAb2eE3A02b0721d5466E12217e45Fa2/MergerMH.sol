// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "IERC721.sol";
import "ERC721.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";
import "ISimpleLimitedMinter.sol";

contract MergerMH is ERC721, Ownable, ReentrancyGuard {
    address public constant burnAddress = address(0x000000000000000000000000000000000000dEaD);

    string internal baseURI;
    bool internal isLockedURI;

    address public immutable nftAddress;
    address public immutable rewardAddress;
    // NFTs from 'offset + 1' to 'offset + elementsCount * editionsCount' can be merged
    uint16 internal immutable offset; //NFTs that don't take part in merging
    uint16 internal immutable elementsCount;
    uint16 internal immutable editionsCount;
    uint16[] internal startTokenIds;

    constructor(string memory name_, string memory symbol_,
                address nftAddress_, address rewardAddress_, string memory baseURI_,
                uint16 offset_, uint16 elementsCount_, uint16 editionsCount_) payable ERC721(name_, symbol_) {
        nftAddress = nftAddress_;
        rewardAddress = rewardAddress_;
        baseURI = baseURI_;
        offset = offset_;
        elementsCount = elementsCount_;
        editionsCount = editionsCount_;

        uint16 totalMergesCount = editionsCount_ - 1; // 16 editions gives 8 + 4 + 2 + 1 = (16 - 1) merges (complete binary tree nodes count)
        require(totalMergesCount * elementsCount_ <= type(uint16).max, "Too many elements");

        uint16 startId = 1; // start, so must add 1
        startTokenIds.push(startId);
        for (uint16 mergesCount = editionsCount_ / 2; mergesCount > 0; mergesCount /= 2) {
            startId += mergesCount; // if 16 editions, then: +8, +4, +2, +1
            startTokenIds.push(startId);
        }
    }

    // lock metadata forever
    function lockURI() external onlyOwner {
        isLockedURI = true;
    }

    // modify the base URI
    function changeBaseURI(string memory newBaseURI) onlyOwner external
    {
        require(!isLockedURI, "URI change has been locked");
        baseURI = newBaseURI;
    }

    // return Base URI
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function getTokenInfo(uint256 tokenId) external view returns (uint256 tokenNumber, uint256 level) {
        uint256 totalMergesCount = editionsCount - 1; // explained in constructor
        uint256 elementIndex = (tokenId - 1) / totalMergesCount;
        tokenNumber = elementIndex + offset + 1; // start from 1

        uint256 elementOffset = elementIndex * totalMergesCount;
        for (uint256 i = 1; i < startTokenIds.length; i++) { // level starts from 1
            uint256 nextLevelId = elementOffset + startTokenIds[i];
            if (tokenId >= nextLevelId) continue;
            return (tokenNumber, i);
        }

        return (tokenNumber, startTokenIds.length); // level starts from 1
    }

    // merge n NFTs of 0th level into one of high level (from other contract - nftAddress)
    function mergeBaseBatch(uint256[] memory tokenIds) external nonReentrant returns (uint256) {
        uint256 countToMerge = tokenIds.length;
        unchecked { // compute a power of two less than or equal to `countToMerge`
            while (countToMerge & countToMerge - 1 != 0) {
                countToMerge = countToMerge & countToMerge - 1;
            }
        }
        require(countToMerge >= 2, "Not enough tokens");
        require(msg.sender == tx.origin, "Sender must be a wallet");

        IERC721 nftContract = IERC721(nftAddress);

        uint256 elementIndex;

        for(uint256 i = 0; i < countToMerge; i++) {
            uint256 tokenId = tokenIds[i];
            require(msg.sender == nftContract.ownerOf(tokenId), "Sender must be an owner");
            require(tokenId > offset, "Cannot merge unique token");
            for(uint256 j = i + 1; j < countToMerge; j++) {
                require(tokenId != tokenIds[j], "Cannot merge token with self");
            }
            // tokenId can be calculated with this formula: tokenId = offset + elementsCount * editionIndex + elementId
            // index is 1 less than the identifier: elementIndex = elementId - 1
            if (i == 0) {
                elementIndex = (tokenId - offset - 1) % elementsCount;
            } else {
                require((tokenId - offset - 1) % elementsCount == elementIndex, "Cannot merge different elements");
            }
        }

        uint256 totalMergesCount = editionsCount - 1; // explained in constructor
        uint256 elementOffset = elementIndex * totalMergesCount; // resulting offset

        uint256 level;
        for (level = 0; level < startTokenIds.length; level++) {
            if (countToMerge == 1 << level) break;
        }

        uint256 endId = elementOffset + startTokenIds[level];

        for (uint256 mintingTokenId = elementOffset + startTokenIds[level - 1]; mintingTokenId < endId; mintingTokenId++) {
            if (_exists(mintingTokenId)) continue; // trying to find next token id
            // burning merged tokens
            for (uint256 i = 0; i < countToMerge; i++) {
                nftContract.transferFrom(msg.sender, burnAddress, tokenIds[i]);
            }

            _mint(msg.sender, mintingTokenId);
             // reward user
            if (level > 1) { // can be rewarded only for 4+ tokens
                uint256 rewardsCount = (countToMerge >> 1) - 1; // 4 -> 1 (start), 8 -> 3 (3 rewards: for 4, 4, and 8)
                for (uint256 reward = 0; reward < rewardsCount; reward++) {
                    ISimpleLimitedMinter(rewardAddress).tryMint(msg.sender);
                }
            }

            return mintingTokenId;
        }

        revert("ERROR"); // cannot merge
    }

    // merge 2 NFTs with n level into one with n+1 level (from this contract)
    function mergeAdvanced(uint256 tokenId1, uint256 tokenId2) external nonReentrant returns (uint256) {
        require(msg.sender == tx.origin, "Sender must be a wallet");
        require(msg.sender == ownerOf(tokenId1) && msg.sender == ownerOf(tokenId2), "Sender must be an owner");
        require(tokenId1 != tokenId2, "Cannot merge token with self");

        uint256 totalMergesCount = editionsCount - 1; // explained in constructor

        uint256 elementIndex = tokenId1 / totalMergesCount;
        require(tokenId2 / totalMergesCount == elementIndex, "Cannot merge different tokens");

        uint256 elementOffset = elementIndex * totalMergesCount;

        uint256 lastIndex = startTokenIds.length - 2; // skip last level - it cannot be merged
        for (uint256 level = 0; level <= lastIndex; level++) {
            // tokens must belong to [currentLevelId, nextLevelId) interval
            uint256 nextLevelId = elementOffset + startTokenIds[level + 1];
            if (tokenId1 >= nextLevelId) continue;
            uint256 currentLevelId = elementOffset + startTokenIds[level];
            require(tokenId2 >= currentLevelId && tokenId2 < nextLevelId, "Cannot merge different levels");

            // burning merged tokens
            _transfer(msg.sender, burnAddress, tokenId1);
            _transfer(msg.sender, burnAddress, tokenId2);

            uint256 endId = elementOffset + startTokenIds[level + 2];

            for (uint256 mintingTokenId = nextLevelId; mintingTokenId < endId; mintingTokenId++) {
                if (_exists(mintingTokenId)) continue; // trying to find next token id

                _mint(msg.sender, mintingTokenId);

                ISimpleLimitedMinter(rewardAddress).tryMint(msg.sender); // reward user

                return mintingTokenId;
            }
        }
        revert("ERROR"); // something went wrong
    }
}
