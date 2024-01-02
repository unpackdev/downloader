// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./Ownable.sol";

import "./IERC20MintBurnable.sol";
import "./IVerifiedContributorStaking.sol";

contract VerifiedContributorStaking is Ownable, IVerifiedContributorStaking {
    uint256 public immutable tokensPerSecond;
    IERC20MintBurnable public immutable rewardToken;
    IERC721 public immutable stakeNFT;
    uint64 internal stakingOver = type(uint64).max;
    mapping(uint256 => uint64) private lastClaim;

    constructor(
        IERC20MintBurnable _rewardToken,
        IERC721 _stakeNFT,
        uint256 _tokensPerSecond,
        address _admin
    ) Ownable(_admin) {
        rewardToken = _rewardToken;
        stakeNFT = _stakeNFT;
        tokensPerSecond = _tokensPerSecond;
    }

    /// @inheritdoc IVerifiedContributorStaking
    function stake(uint256 _tokenId) external {
        if (stakeNFT.ownerOf(_tokenId) != msg.sender) {
            revert NotYourNFT();
        }
        if (lastClaim[_tokenId] != 0) {
            revert NFTAlreadyStaked();
        }

        lastClaim[_tokenId] = _toUint64(block.timestamp);
        emit NFTStaked(_tokenId);
    }

    /// @inheritdoc IVerifiedContributorStaking
    function unstake(uint256 _tokenId) external {
        if (stakeNFT.ownerOf(_tokenId) != msg.sender) {
            revert NotYourNFT();
        }

        _claim(_tokenId);

        lastClaim[_tokenId] = 0;
        emit NFTUnstaked(_tokenId);
    }

    /// @inheritdoc IVerifiedContributorStaking
    function claimable(
        uint256 _tokenId
    ) public view returns (uint256 claimableTokens) {
        uint64 currentSeconds = _toUint64(block.timestamp);
        uint64 lastClaimSeconds = lastClaim[_tokenId];
        if (lastClaimSeconds == 0) {
            revert NFTNotStaked();
        }

        if (currentSeconds > stakingOver) {
            if (lastClaimSeconds < stakingOver) {
                // Staking is over && havent claimed remaining tokens up until end date yet
                return (stakingOver - lastClaimSeconds) * tokensPerSecond;
            } else {
                // Staking is over && all leftover have been claimed
                return 0;
            }
        }

        return (currentSeconds - lastClaimSeconds) * tokensPerSecond;
    }

    /// @inheritdoc IVerifiedContributorStaking
    function claim(uint256 _tokenId) external {
        _claim(_tokenId);

        lastClaim[_tokenId] = _toUint64(block.timestamp);
    }

    /// Set enddate for rewards. No new rewards are stacked up after this date.
    /// @param _stakingOver The enddate.
    /// @notice Rewards stacked up until this date can still be claimed.
    function setStakingEnd(uint64 _stakingOver) external onlyOwner {
        if (block.timestamp > _stakingOver) {
            revert StakingEndMustBeInTheFuture();
        }

        stakingOver = _stakingOver;
    }

    /// Safecast uint256 to uint64.
    /// @param value The uint256 to cast.
    function _toUint64(uint256 value) internal pure returns (uint64) {
        if (value > type(uint64).max) {
            revert Overflow();
        }
        return uint64(value);
    }

    /// Mints claimable tokens to the NFT owner.
    /// @param _tokenId The NFT to claim the tokens for.
    /// @dev Due to gas optimization this does not update lastClaim, IS SHOULD ALWAYS BE UPDATED.
    function _claim(uint256 _tokenId) internal {
        uint256 tokens = claimable(_tokenId);
        rewardToken.mint(stakeNFT.ownerOf(_tokenId), tokens);
        emit TokensClaimed(_tokenId, tokens);
    }
}
