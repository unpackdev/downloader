// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./D4AEnums.sol";

struct DaoMetadataParam {
    uint256 startDrb;
    uint256 mintableRounds;
    uint256 floorPriceRank;
    uint256 maxNftRank;
    uint96 royaltyFee;
    string projectUri;
    uint256 projectIndex;
}

struct DaoMintInfo {
    uint32 daoMintCap;
    uint32 NFTHolderMintCap;
    mapping(address minter => UserMintInfo) userMintInfos;
}

struct UserMintInfo {
    uint32 minted;
    uint32 mintCap;
}

struct DaoMintCapParam {
    uint32 daoMintCap;
    UserMintCapParam[] userMintCapParams;
}

struct UserMintCapParam {
    address minter;
    uint32 mintCap;
}

struct DaoETHAndERC20SplitRatioParam {
    uint256 daoCreatorERC20Ratio;
    uint256 canvasCreatorERC20Ratio;
    uint256 nftMinterERC20Ratio;
    uint256 daoFeePoolETHRatio;
    uint256 daoFeePoolETHRatioFlatPrice;
}

struct TemplateParam {
    PriceTemplateType priceTemplateType;
    uint256 priceFactor;
    RewardTemplateType rewardTemplateType;
    uint256 rewardDecayFactor;
    bool isProgressiveJackpot;
}

struct UpdateRewardParam {
    bytes32 daoId;
    bytes32 canvasId;
    address token;
    uint256 startRound;
    uint256 currentRound;
    uint256 totalRound;
    uint256 daoFeeAmount;
    uint256 protocolERC20RatioInBps;
    uint256 daoCreatorERC20RatioInBps;
    uint256 canvasCreatorERC20RatioInBps;
    uint256 nftMinterERC20RatioInBps;
    uint256 canvasRebateRatioInBps;
}

struct MintNftInfo {
    string tokenUri;
    uint256 flatPrice;
}

struct Blacklist {
    address[] minterAccounts;
    address[] canvasCreatorAccounts;
}

struct Whitelist {
    bytes32 minterMerkleRoot;
    address[] minterNFTHolderPasses;
    bytes32 canvasCreatorMerkleRoot;
    address[] canvasCreatorNFTHolderPasses;
}

struct BasicDaoParam {
    uint256 initTokenSupplyRatio;
    bytes32 canvasId;
    string canvasUri;
    string daoName;
}
