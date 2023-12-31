// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./D4AConstants.sol";
import "./D4AEnums.sol";
import "./DaoStorage.sol";
import "./CanvasStorage.sol";
import "./PriceStorage.sol";
import "./RewardStorage.sol";
import "./SettingsStorage.sol";
import "./ID4AProtocolReadable.sol";
import "./IPriceTemplate.sol";
import "./IRewardTemplate.sol";

contract D4AProtocolReadable is ID4AProtocolReadable {
    // legacy functions
    function getProjectCanvasAt(bytes32 daoId, uint256 index) public view returns (bytes32) {
        return DaoStorage.layout().daoInfos[daoId].canvases[index];
    }

    function getProjectInfo(bytes32 daoId)
        public
        view
        returns (
            uint256 startRound,
            uint256 mintableRound,
            uint256 nftMaxSupply,
            address daoFeePool,
            uint96 royaltyFeeRatioInBps,
            uint256 daoIndex,
            string memory daoUri,
            uint256 tokenMaxSupply
        )
    {
        DaoStorage.DaoInfo storage pi = DaoStorage.layout().daoInfos[daoId];
        startRound = pi.startRound;
        mintableRound = pi.mintableRound;
        nftMaxSupply = pi.nftMaxSupply;
        daoFeePool = pi.daoFeePool;
        royaltyFeeRatioInBps = pi.royaltyFeeRatioInBps;
        daoIndex = pi.daoIndex;
        daoUri = pi.daoUri;
        tokenMaxSupply = pi.tokenMaxSupply;
    }

    function getProjectFloorPrice(bytes32 daoId) public view returns (uint256) {
        return PriceStorage.layout().daoFloorPrices[daoId];
    }

    function getProjectTokens(bytes32 daoId) public view returns (address token, address nft) {
        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        token = daoInfo.token;
        nft = daoInfo.nft;
    }

    function getCanvasNFTCount(bytes32 canvasId) public view returns (uint256) {
        return CanvasStorage.layout().canvasInfos[canvasId].tokenIds.length;
    }

    function getTokenIDAt(bytes32 canvasId, uint256 index) public view returns (uint256) {
        return CanvasStorage.layout().canvasInfos[canvasId].tokenIds[index];
    }

    function getCanvasProject(bytes32 canvasId) public view returns (bytes32) {
        return CanvasStorage.layout().canvasInfos[canvasId].daoId;
    }

    function getCanvasURI(bytes32 canvasId) public view returns (string memory) {
        return CanvasStorage.layout().canvasInfos[canvasId].canvasUri;
    }

    function getProjectCanvasCount(bytes32 daoId) public view returns (uint256) {
        return DaoStorage.layout().daoInfos[daoId].canvases.length;
    }

    // new functions
    // DAO related functions
    function getDaoStartRound(bytes32 daoId) external view returns (uint256 startRound) {
        return DaoStorage.layout().daoInfos[daoId].startRound;
    }

    function getDaoMintableRound(bytes32 daoId) external view returns (uint256 mintableRound) {
        return DaoStorage.layout().daoInfos[daoId].mintableRound;
    }

    function getDaoIndex(bytes32 daoId) external view returns (uint256 index) {
        return DaoStorage.layout().daoInfos[daoId].daoIndex;
    }

    function getDaoUri(bytes32 daoId) external view returns (string memory daoUri) {
        return DaoStorage.layout().daoInfos[daoId].daoUri;
    }

    function getDaoFeePool(bytes32 daoId) external view returns (address daoFeePool) {
        return DaoStorage.layout().daoInfos[daoId].daoFeePool;
    }

    function getDaoToken(bytes32 daoId) external view returns (address token) {
        return DaoStorage.layout().daoInfos[daoId].token;
    }

    function getDaoTokenMaxSupply(bytes32 daoId) external view returns (uint256 tokenMaxSupply) {
        return DaoStorage.layout().daoInfos[daoId].tokenMaxSupply;
    }

    function getDaoNft(bytes32 daoId) external view returns (address nft) {
        return DaoStorage.layout().daoInfos[daoId].nft;
    }

    function getDaoNftMaxSupply(bytes32 daoId) external view returns (uint256 nftMaxSupply) {
        return DaoStorage.layout().daoInfos[daoId].nftMaxSupply;
    }

    function getDaoNftTotalSupply(bytes32 daoId) external view returns (uint256 nftTotalSupply) {
        return DaoStorage.layout().daoInfos[daoId].nftTotalSupply;
    }

    function getDaoNftRoyaltyFeeRatioInBps(bytes32 daoId) external view returns (uint96 royaltyFeeRatioInBps) {
        return DaoStorage.layout().daoInfos[daoId].royaltyFeeRatioInBps;
    }

    function getDaoExist(bytes32 daoId) external view returns (bool exist) {
        return DaoStorage.layout().daoInfos[daoId].daoExist;
    }

    function getDaoCanvases(bytes32 daoId) external view returns (bytes32[] memory canvases) {
        return DaoStorage.layout().daoInfos[daoId].canvases;
    }

    function getDaoPriceTemplate(bytes32 daoId) external view returns (address priceTemplate) {
        return SettingsStorage.layout().priceTemplates[uint8(DaoStorage.layout().daoInfos[daoId].priceTemplateType)];
    }

    function getDaoPriceFactor(bytes32 daoId) external view returns (uint256 priceFactor) {
        return DaoStorage.layout().daoInfos[daoId].nftPriceFactor;
    }

    function getDaoRewardTemplate(bytes32 daoId) external view override returns (address rewardTemplate) {
        return SettingsStorage.layout().rewardTemplates[uint8(DaoStorage.layout().daoInfos[daoId].rewardTemplateType)];
    }

    function getDaoMintCap(bytes32 daoId) public view returns (uint32) {
        return DaoStorage.layout().daoInfos[daoId].daoMintInfo.daoMintCap;
    }

    function getDaoNftHolderMintCap(bytes32 daoId) public view returns (uint32) {
        return DaoStorage.layout().daoInfos[daoId].daoMintInfo.NFTHolderMintCap;
    }

    function getUserMintInfo(bytes32 daoId, address account) public view returns (uint32 minted, uint32 userMintCap) {
        minted = DaoStorage.layout().daoInfos[daoId].daoMintInfo.userMintInfos[account].minted;
        userMintCap = DaoStorage.layout().daoInfos[daoId].daoMintInfo.userMintInfos[account].mintCap;
    }

    function getDaoFeePoolETHRatio(bytes32 daoId) public view returns (uint256) {
        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        if (daoInfo.daoFeePoolETHRatioInBps == 0) {
            return SettingsStorage.layout().daoFeePoolMintFeeRatioInBps;
        }
        return daoInfo.daoFeePoolETHRatioInBps;
    }

    function getDaoFeePoolETHRatioFlatPrice(bytes32 daoId) public view returns (uint256) {
        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        if (daoInfo.daoFeePoolETHRatioInBpsFlatPrice == 0) {
            return SettingsStorage.layout().daoFeePoolMintFeeRatioInBpsFlatPrice;
        }
        return daoInfo.daoFeePoolETHRatioInBpsFlatPrice;
    }

    function getDaoTag(bytes32 daoId) public view returns (string memory) {
        DaoTag tag = DaoStorage.layout().daoInfos[daoId].daoTag;
        if (tag == DaoTag.D4A_DAO) return "D4A DAO";
        else if (tag == DaoTag.BASIC_DAO) return "BASIC DAO";
        else return "";
    }

    // canvas related functions
    function getCanvasDaoId(bytes32 canvasId) external view returns (bytes32 daoId) {
        return CanvasStorage.layout().canvasInfos[canvasId].daoId;
    }

    function getCanvasTokenIds(bytes32 canvasId) external view returns (uint256[] memory tokenIds) {
        return CanvasStorage.layout().canvasInfos[canvasId].tokenIds;
    }

    function getCanvasIndex(bytes32 canvasId) public view returns (uint256) {
        return CanvasStorage.layout().canvasInfos[canvasId].index;
    }

    function getCanvasUri(bytes32 canvasId) external view returns (string memory canvasUri) {
        return CanvasStorage.layout().canvasInfos[canvasId].canvasUri;
    }

    function getCanvasRebateRatioInBps(bytes32 canvasId) public view returns (uint256) {
        return CanvasStorage.layout().canvasInfos[canvasId].canvasRebateRatioInBps;
    }

    function getCanvasExist(bytes32 canvasId) external view returns (bool exist) {
        return CanvasStorage.layout().canvasInfos[canvasId].canvasExist;
    }

    // prices related functions
    function getCanvasLastPrice(bytes32 canvasId) public view returns (uint256 round, uint256 price) {
        PriceStorage.MintInfo storage mintInfo = PriceStorage.layout().canvasLastMintInfos[canvasId];
        return (mintInfo.round, mintInfo.price);
    }

    function getCanvasNextPrice(bytes32 canvasId) public view returns (uint256) {
        bytes32 daoId = CanvasStorage.layout().canvasInfos[canvasId].daoId;
        uint256 daoFloorPrice = PriceStorage.layout().daoFloorPrices[daoId];
        PriceStorage.MintInfo memory maxPrice = PriceStorage.layout().daoMaxPrices[daoId];
        PriceStorage.MintInfo memory mintInfo = PriceStorage.layout().canvasLastMintInfos[canvasId];
        DaoStorage.DaoInfo storage pi = DaoStorage.layout().daoInfos[daoId];
        SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();
        return IPriceTemplate(
            settingsStorage.priceTemplates[uint8(DaoStorage.layout().daoInfos[daoId].priceTemplateType)]
        ).getCanvasNextPrice(
            pi.startRound, settingsStorage.drb.currentRound(), pi.nftPriceFactor, daoFloorPrice, maxPrice, mintInfo
        );
    }

    function getDaoMaxPriceInfo(bytes32 daoId) external view returns (uint256 round, uint256 price) {
        PriceStorage.MintInfo memory maxPrice = PriceStorage.layout().daoMaxPrices[daoId];
        return (maxPrice.round, maxPrice.price);
    }

    function getDaoFloorPrice(bytes32 daoId) external view returns (uint256 floorPrice) {
        return PriceStorage.layout().daoFloorPrices[daoId];
    }

    // reward related functions
    function getDaoRewardStartRound(
        bytes32 daoId,
        uint256 rewardCheckpointIndex
    )
        external
        view
        returns (uint256 startRound)
    {
        return RewardStorage.layout().rewardInfos[daoId].rewardCheckpoints[rewardCheckpointIndex].startRound;
    }

    function getDaoRewardTotalRound(
        bytes32 daoId,
        uint256 rewardCheckpointIndex
    )
        external
        view
        returns (uint256 totalRound)
    {
        return RewardStorage.layout().rewardInfos[daoId].rewardCheckpoints[rewardCheckpointIndex].totalRound;
    }

    function getDaoTotalReward(
        bytes32 daoId,
        uint256 rewardCheckpointIndex
    )
        external
        view
        returns (uint256 totalReward)
    {
        return RewardStorage.layout().rewardInfos[daoId].rewardCheckpoints[rewardCheckpointIndex].totalReward;
    }

    function getDaoRewardDecayFactor(bytes32 daoId) external view returns (uint256 rewardDecayFactor) {
        return RewardStorage.layout().rewardInfos[daoId].rewardDecayFactor;
    }

    function getDaoRewardIsProgressiveJackpot(bytes32 daoId) external view returns (bool isProgressiveJackpot) {
        return RewardStorage.layout().rewardInfos[daoId].isProgressiveJackpot;
    }

    function getDaoRewardLastActiveRound(
        bytes32 daoId,
        uint256 rewardCheckpointIndex
    )
        external
        view
        returns (uint256 lastActiveRound)
    {
        return RewardStorage.layout().rewardInfos[daoId].rewardCheckpoints[rewardCheckpointIndex].lastActiveRound;
    }

    function getDaoRewardActiveRounds(
        bytes32 daoId,
        uint256 rewardCheckpointIndex
    )
        external
        view
        returns (uint256[] memory activeRounds)
    {
        return RewardStorage.layout().rewardInfos[daoId].rewardCheckpoints[rewardCheckpointIndex].activeRounds;
    }

    function getDaoCreatorClaimableRound(
        bytes32 daoId,
        uint256 rewardCheckpointIndex
    )
        external
        view
        returns (uint256 claimableRound)
    {
        RewardStorage.RewardCheckpoint storage rewardCheckpoint =
            RewardStorage.layout().rewardInfos[daoId].rewardCheckpoints[rewardCheckpointIndex];
        return rewardCheckpoint.activeRounds[rewardCheckpoint.daoCreatorClaimableRoundIndex];
    }

    function getCanvasCreatorClaimableRound(
        bytes32 daoId,
        uint256 rewardCheckpointsIndex,
        bytes32 canvasId
    )
        external
        view
        returns (uint256 claimableRound)
    {
        RewardStorage.RewardCheckpoint storage rewardCheckpoint =
            RewardStorage.layout().rewardInfos[daoId].rewardCheckpoints[rewardCheckpointsIndex];
        return rewardCheckpoint.activeRounds[rewardCheckpoint.canvasCreatorClaimableRoundIndexes[canvasId]];
    }

    function getNftMinterClaimableRound(
        bytes32 daoId,
        uint256 rewardCheckpointsIndex,
        address nftMinter
    )
        external
        view
        returns (uint256 claimableRound)
    {
        RewardStorage.RewardCheckpoint storage rewardCheckpoint =
            RewardStorage.layout().rewardInfos[daoId].rewardCheckpoints[rewardCheckpointsIndex];
        return rewardCheckpoint.activeRounds[rewardCheckpoint.nftMinterClaimableRoundIndexes[nftMinter]];
    }

    function getTotalWeight(bytes32 daoId, uint256 round) external view returns (uint256 totalWeight) {
        return RewardStorage.layout().rewardInfos[daoId].totalWeights[round];
    }

    function getProtocolWeight(bytes32 daoId, uint256 round) external view returns (uint256 protocolWeight) {
        return RewardStorage.layout().rewardInfos[daoId].protocolWeights[round];
    }

    function getDaoCreatorWeight(bytes32 daoId, uint256 round) external view returns (uint256 creatorWeight) {
        return RewardStorage.layout().rewardInfos[daoId].daoCreatorWeights[round];
    }

    function getCanvasCreatorWeight(
        bytes32 daoId,
        uint256 round,
        bytes32 canvasId
    )
        external
        view
        returns (uint256 creatorWeight)
    {
        return RewardStorage.layout().rewardInfos[daoId].canvasCreatorWeights[round][canvasId];
    }

    function getNftMinterWeight(
        bytes32 daoId,
        uint256 round,
        address nftMinter
    )
        external
        view
        returns (uint256 minterWeight)
    {
        return RewardStorage.layout().rewardInfos[daoId].nftMinterWeights[round][nftMinter];
    }

    function getDaoCreatorERC20Ratio(bytes32 daoId) public view returns (uint256) {
        SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();
        uint256 daoCreatorERC20RatioInBps = RewardStorage.layout().rewardInfos[daoId].daoCreatorERC20RatioInBps;
        if (daoCreatorERC20RatioInBps == 0) {
            return settingsStorage.daoCreatorERC20RatioInBps;
        }
        return (daoCreatorERC20RatioInBps * (BASIS_POINT - settingsStorage.protocolERC20RatioInBps)) / BASIS_POINT;
    }

    function getCanvasCreatorERC20Ratio(bytes32 daoId) public view returns (uint256) {
        SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();
        uint256 canvasCreatorERC20RatioInBps = RewardStorage.layout().rewardInfos[daoId].canvasCreatorERC20RatioInBps;
        if (canvasCreatorERC20RatioInBps == 0) {
            return settingsStorage.canvasCreatorERC20RatioInBps;
        }
        return (canvasCreatorERC20RatioInBps * (BASIS_POINT - settingsStorage.protocolERC20RatioInBps)) / BASIS_POINT;
    }

    function getNftMinterERC20Ratio(bytes32 daoId) public view returns (uint256) {
        return BASIS_POINT - SettingsStorage.layout().protocolERC20RatioInBps - getDaoCreatorERC20Ratio(daoId)
            - getCanvasCreatorERC20Ratio(daoId);
    }

    function getRoundReward(bytes32 daoId, uint256 round) public view returns (uint256) {
        return _castGetRoundRewardToView(_getRoundReward)(daoId, round);
    }

    function getRewardTillRound(bytes32 daoId, uint256 round) public view returns (uint256) {
        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];
        RewardStorage.RewardCheckpoint[] storage rewardCheckpoints = rewardInfo.rewardCheckpoints;

        uint256 totalRoundReward;
        for (uint256 i; i < rewardCheckpoints.length; i++) {
            uint256[] memory activeRounds = rewardCheckpoints[i].activeRounds;
            for (uint256 j; j < activeRounds.length && activeRounds[j] <= round; j++) {
                totalRoundReward += getRoundReward(daoId, activeRounds[j]);
            }
        }

        return totalRoundReward;
    }

    function _getRoundReward(bytes32 daoId, uint256 round) internal returns (uint256) {
        address rewardTemplate =
            SettingsStorage.layout().rewardTemplates[uint8(DaoStorage.layout().daoInfos[daoId].rewardTemplateType)];

        (bool succ, bytes memory data) =
            rewardTemplate.delegatecall(abi.encodeWithSelector(IRewardTemplate.getRoundReward.selector, daoId, round));
        if (!succ) {
            /// @solidity memory-safe-assembly
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
        return abi.decode(data, (uint256));
    }

    function _castGetRoundRewardToView(function(bytes32, uint256) internal returns (uint256) fnIn)
        internal
        pure
        returns (function(bytes32, uint256) internal view returns (uint256) fnOut)
    {
        assembly {
            fnOut := fnIn
        }
    }
}