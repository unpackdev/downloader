// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./IERC721Enumerable.sol";

import "./IBNFTRegistry.sol";

import "./ICoinPool.sol";
import "./INftPool.sol";
import "./IStakeManager.sol";

/**
 * @title BendDAO Staked ApeCoin's Voting Contract
 * @notice Provides a comprehensive vote count across all pools in the ApeCoinStaking contract
 */
contract BendApeCoinStakedVoting {
    ICoinPool public immutable coinPool;
    INftPool public immutable nftPool;
    IStakeManager public immutable staker;
    IBNFTRegistry public immutable bnftRegistry;

    constructor(ICoinPool coinPool_, INftPool nftPool_, IStakeManager staker_, IBNFTRegistry bnftRegistry_) {
        coinPool = coinPool_;
        nftPool = nftPool_;
        staker = staker_;
        bnftRegistry = bnftRegistry_;
    }

    /**
     * @notice Returns a vote count across all pools in the ApeCoinStaking contract for a given address
     * @param userAddress The address to return votes for
     */
    function getVotes(address userAddress) public view returns (uint256 votes) {
        votes += getVotesInCoinPool(userAddress);
        votes += getVotesInAllNftPool(userAddress);
    }

    function getVotesInCoinPool(address userAddress) public view returns (uint256 votes) {
        votes = coinPool.assetBalanceOf(userAddress);
    }

    function getVotesInAllNftPool(address userAddress) public view returns (uint256 votes) {
        votes += getVotesInOneNftPool(staker.stBayc(), userAddress);
        votes += getVotesInOneNftPool(staker.stMayc(), userAddress);
        votes += getVotesInOneNftPool(staker.stBakc(), userAddress);
    }

    function getVotesInOneNftPool(IStakedNft stnft_, address userAddress) public view returns (uint256 votes) {
        // Check user balance
        uint256 stnftBalance = stnft_.balanceOf(userAddress);
        uint256 bnftBalance;
        (address bnftProxy, ) = bnftRegistry.getBNFTAddresses(address(stnft_));
        if (bnftProxy != address(0)) {
            bnftBalance += IERC721Enumerable(bnftProxy).balanceOf(userAddress);
        }
        if (bnftBalance == 0 && stnftBalance == 0) {
            return 0;
        }

        // Get all tokenIds
        uint256[] memory allTokenIds = new uint256[](stnftBalance + bnftBalance);
        uint256 allIdSize = 0;

        for (uint256 i = 0; i < stnftBalance; i++) {
            uint256 tokenId = stnft_.tokenOfOwnerByIndex(userAddress, i);
            if (stnft_.stakerOf(tokenId) == address(staker)) {
                allTokenIds[allIdSize] = tokenId;
                allIdSize++;
            }
        }

        if (bnftProxy != address(0)) {
            IERC721Enumerable bnft = IERC721Enumerable(bnftProxy);
            for (uint256 i = 0; i < bnftBalance; i++) {
                uint256 tokenId = bnft.tokenOfOwnerByIndex(userAddress, i);
                if (stnft_.stakerOf(tokenId) == address(staker)) {
                    allTokenIds[allIdSize] = tokenId;
                    allIdSize++;
                }
            }
        }

        // Get votes from claimable rewards
        address[] memory claimNfts = new address[](1);
        claimNfts[0] = stnft_.underlyingAsset();

        uint256[][] memory claimTokenIds = new uint256[][](1);
        claimTokenIds[0] = new uint256[](allIdSize);
        for (uint256 i = 0; i < allIdSize; i++) {
            claimTokenIds[0][i] = allTokenIds[i];
        }

        votes = nftPool.claimable(claimNfts, claimTokenIds);
    }
}
