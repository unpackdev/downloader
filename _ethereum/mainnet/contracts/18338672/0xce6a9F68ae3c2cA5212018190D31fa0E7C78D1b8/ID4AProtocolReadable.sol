// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface ID4AProtocolReadable {
    // legacy functions
    function getProjectCanvasAt(bytes32 daoId, uint256 index) external view returns (bytes32);

    function getProjectInfo(bytes32 daoId)
        external
        view
        returns (
            uint256 startRound,
            uint256 mintableRound,
            uint256 maxNftAmount,
            address daoFeePool,
            uint96 royaltyFeeRatioInBps,
            uint256 index,
            string memory daoUri,
            uint256 erc20TotalSupply
        );

    function getProjectFloorPrice(bytes32 daoId) external view returns (uint256);

    function getProjectTokens(bytes32 daoId) external view returns (address token, address nft);

    function getCanvasNFTCount(bytes32 canvasId) external view returns (uint256);

    function getTokenIDAt(bytes32 canvasId, uint256 index) external view returns (uint256);

    function getCanvasProject(bytes32 canvasId) external view returns (bytes32);

    function getCanvasURI(bytes32 canvasId) external view returns (string memory);

    function getProjectCanvasCount(bytes32 daoId) external view returns (uint256);

    // new functions
    // DAO related functions
    function getDaoStartRound(bytes32 daoId) external view returns (uint256 startRound);

    function getDaoMintableRound(bytes32 daoId) external view returns (uint256 mintableRound);

    function getDaoIndex(bytes32 daoId) external view returns (uint256 index);

    function getDaoUri(bytes32 daoId) external view returns (string memory daoUri);

    function getDaoFeePool(bytes32 daoId) external view returns (address daoFeePool);

    function getDaoToken(bytes32 daoId) external view returns (address token);

    function getDaoTokenMaxSupply(bytes32 daoId) external view returns (uint256 tokenMaxSupply);

    function getDaoNft(bytes32 daoId) external view returns (address nft);

    function getDaoNftMaxSupply(bytes32 daoId) external view returns (uint256 nftMaxSupply);

    function getDaoNftTotalSupply(bytes32 daoId) external view returns (uint256 nftTotalSupply);

    function getDaoNftRoyaltyFeeRatioInBps(bytes32 daoId) external view returns (uint96 royaltyFeeRatioInBps);

    function getDaoExist(bytes32 daoId) external view returns (bool);

    function getDaoCanvases(bytes32 daoId) external view returns (bytes32[] memory canvases);

    function getDaoPriceTemplate(bytes32 daoId) external view returns (address priceTemplate);

    function getDaoPriceFactor(bytes32 daoId) external view returns (uint256 priceFactor);

    function getDaoRewardTemplate(bytes32 daoId) external view returns (address rewardTemplate);

    function getDaoMintCap(bytes32 daoId) external view returns (uint32);

    function getDaoNftHolderMintCap(bytes32 daoId) external view returns (uint32);

    function getUserMintInfo(
        bytes32 daoId,
        address account
    )
        external
        view
        returns (uint32 minted, uint32 userMintCap);

    function getDaoFeePoolETHRatio(bytes32 daoId) external view returns (uint256);

    function getDaoFeePoolETHRatioFlatPrice(bytes32 daoId) external view returns (uint256);

    function getDaoTag(bytes32 daoId) external view returns (string memory);

    // canvas related functions
    function getCanvasDaoId(bytes32 canvasId) external view returns (bytes32 daoId);

    function getCanvasTokenIds(bytes32 canvasId) external view returns (uint256[] memory tokenIds);

    function getCanvasIndex(bytes32 canvasId) external view returns (uint256);

    function getCanvasUri(bytes32 canvasId) external view returns (string memory canvasUri);

    function getCanvasRebateRatioInBps(bytes32 canvasId) external view returns (uint256 rebateRatioInBps);

    function getCanvasExist(bytes32 canvasId) external view returns (bool);

    // prices related functions
    function getCanvasLastPrice(bytes32 canvasId) external view returns (uint256 round, uint256 price);

    function getCanvasNextPrice(bytes32 canvasId) external view returns (uint256 price);

    function getDaoMaxPriceInfo(bytes32 daoId) external view returns (uint256 round, uint256 price);

    function getDaoFloorPrice(bytes32 daoId) external view returns (uint256 floorPrice);

    function getDaoDailyMintCap(bytes32 daoId) external view returns (uint256);

    function getDaoUnifiedPriceModeOff(bytes32 daoId) external view returns (bool);

    function getDaoUnifiedPrice(bytes32 daoId) external view returns (uint256);

    function getDaoReserveNftNumber(bytes32 daoId) external view returns (uint256);

    // reward related functions
    function getDaoRewardStartRound(
        bytes32 daoId,
        uint256 rewardCheckpointIndex
    )
        external
        view
        returns (uint256 startRound);

    function getDaoRewardTotalRound(
        bytes32 daoId,
        uint256 rewardCheckpointIndex
    )
        external
        view
        returns (uint256 totalRound);

    function getDaoTotalReward(
        bytes32 daoId,
        uint256 rewardCheckpointIndex
    )
        external
        view
        returns (uint256 totalReward);

    function getDaoRewardDecayFactor(bytes32 daoId) external view returns (uint256 rewardDecayFactor);

    function getDaoRewardIsProgressiveJackpot(bytes32 daoId) external view returns (bool isProgressiveJackpot);

    function getDaoRewardLastActiveRound(
        bytes32 daoId,
        uint256 rewardCheckpointIndex
    )
        external
        view
        returns (uint256 lastActiveRound);

    function getDaoRewardActiveRounds(
        bytes32 daoId,
        uint256 rewardCheckpointIndex
    )
        external
        view
        returns (uint256[] memory activeRounds);

    function getDaoCreatorClaimableRound(
        bytes32 daoId,
        uint256 rewardCheckpointsIndex
    )
        external
        view
        returns (uint256 claimableRound);

    function getCanvasCreatorClaimableRound(
        bytes32 daoId,
        uint256 rewardCheckpointsIndex,
        bytes32 canvasId
    )
        external
        view
        returns (uint256 claimableRound);

    function getNftMinterClaimableRound(
        bytes32 daoId,
        uint256 rewardCheckpointsIndex,
        address nftMinter
    )
        external
        view
        returns (uint256 claimableRound);

    function getTotalWeight(bytes32 daoId, uint256 round) external view returns (uint256 totalWeight);

    function getProtocolWeight(bytes32 daoId, uint256 round) external view returns (uint256 protocolWeight);

    function getDaoCreatorWeight(bytes32 daoId, uint256 round) external view returns (uint256 creatorWeight);

    function getCanvasCreatorWeight(
        bytes32 daoId,
        uint256 round,
        bytes32 canvasId
    )
        external
        view
        returns (uint256 creatorWeight);

    function getNftMinterWeight(
        bytes32 daoId,
        uint256 round,
        address nftMinter
    )
        external
        view
        returns (uint256 minterWeight);

    function getDaoCreatorERC20Ratio(bytes32 daoId) external view returns (uint256 ratioInBps);

    function getCanvasCreatorERC20Ratio(bytes32 daoId) external view returns (uint256 ratioInBps);

    function getNftMinterERC20Ratio(bytes32 daoId) external view returns (uint256 ratioInBps);

    function getRoundReward(bytes32 daoId, uint256 round) external view returns (uint256);

    function getRewardTillRound(bytes32 daoId, uint256 round) external view returns (uint256);
}
