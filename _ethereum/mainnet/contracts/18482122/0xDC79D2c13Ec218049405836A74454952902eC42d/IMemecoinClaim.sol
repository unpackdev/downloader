// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./IERC721.sol";
import "./Errors.sol";
import "./Structs.sol";

interface IMemecoinClaim {
    event UserClaimed(address indexed user, uint128 amount, uint256 claimedAt);
    event ClaimedInNFTs(address indexed owner, uint128 amount, uint256 claimedAt);
    event ClaimStatusUpdated(bool claimActive);
    event UpgraderUpdated(address newUpgrader);
    event UnclaimedNFTRewardsWithdrawn(uint256 totalWithdrawn, uint256 withdrawnAt);
    event ClaimTokenDepositedAndClaimStarted(uint256 tokenAmount, uint256 claimStartDate);

    function claim(address _vault, ClaimType[] calldata _claimTypes) external;
    function claimInNFTs(
        address _vault,
        NFTCollectionClaimRequest[] calldata _nftCollectionClaimRequests,
        bool _withWalletRewards
    ) external;

    function claimFromMulti(address _requester, ClaimType[] calldata _claimTypes) external;
    function claimInNFTsFromMulti(
        address _requester,
        NFTCollectionClaimRequest[] calldata _nftCollectionClaimRequests,
        bool _withWalletRewards
    ) external;

    function setClaimables(
        address[] calldata _addresses,
        uint128[] calldata _claimables,
        ClaimType[] calldata _claimTypes
    ) external;
    function setNFTClaimables(NFTClaimable[] calldata _nftClaimables) external;
    function addNFTUnlockedBPAndSetUnlockTs(uint64 _additionalNFTUnlockedBP, uint128 _newUnlockedBPEffectiveTs)
        external;
    function setUnclaimedNFTRewards(uint256 _collectionId, uint128[] calldata _unclaimTokenIds) external;
    function setRevealedCaptainzClaimable(uint256 _tokenId, uint128 _additionalAirdropTotalClaimable) external;

    function depositClaimTokenAndStartClaim(uint256 _tokenAmount, uint256 _claimStartDate) external;
    function withdrawClaimToken(address _receiver, uint256 _amount) external;
    function withdrawUnclaimedNFTRewards(address _receiver) external;

    function setClaimSchedules(ClaimType[] calldata _claimTypes, ClaimSchedule[] calldata _claimSchedules) external;
    function setClaimActive(bool _claimActive) external;
    function setClaimStartDate(uint256 _claimStartDate) external;

    function setMultiClaimAddress(address _multiClaim) external;
    function setUpgrader(address _upgrader) external;

    function getClaimInfo(address _user, ClaimType _claimType)
        external
        returns (uint128 claimableAmount, uint256 claimableExpiry);
    function getClaimInfoByNFT(uint256 _collectionId, uint256 _tokenId)
        external
        returns (uint128 claimableAmount, uint256 claimableExpiry);
    function getRewardsClaimInfoByNFT(uint256 _collectionId, uint256 _tokenId)
        external
        returns (uint128 claimableAmount, uint256 claimableExpiry);
    function getTotalClaimableAmountsByNFTs(uint256 _collectionId, uint256[] calldata _tokenIds)
        external
        returns (uint128 totalClaimable);
    function getUserClaimDataByCollections(NFTCollectionInfo[] calldata _nftCollectionInfo)
        external
        returns (CollectionClaimData[] memory collectionClaimInfo);
    function getClaimSchedule(ClaimType _claimType) external returns (ClaimSchedule memory);
}
