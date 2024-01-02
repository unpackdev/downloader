// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./Ownable.sol";

import "./IERC20MintBurnable.sol";

interface IVerifiedContributorStaking {
    error NotYourNFT();
    error NFTAlreadyStaked();
    error NFTNotStaked();
    error StakingEndMustBeInTheFuture();
    error Overflow();

    event NFTStaked(uint256 indexed tokenId);
    event TokensClaimed(uint256 indexed tokenId, uint256 tokens);
    event NFTUnstaked(uint256 indexed tokenId);

    /// Stakes your NFT.
    /// @param _tokenId The id of the NFT to stake.
    function stake(uint256 _tokenId) external;

    /// Unstakes your NFT.
    /// @param _tokenId The id of the NFT to unstake.
    function unstake(uint256 _tokenId) external;

    /// Checks how much tokens are claimable.
    /// @param _tokenId The id of the NFT to check claimable tokens.
    function claimable(
        uint256 _tokenId
    ) external view returns (uint256 claimableTokens);

    /// Claims all claimable tokens.
    /// @param _tokenId The id of the NFT to claim tokens for.
    /// @notice Can be called by any wallet, but tokens will be claimed to NFT owner.
    function claim(uint256 _tokenId) external;
}
