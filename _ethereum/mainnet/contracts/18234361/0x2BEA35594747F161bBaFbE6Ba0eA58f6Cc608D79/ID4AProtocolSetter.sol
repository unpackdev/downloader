// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./D4AStructs.sol";
import "./D4AEnums.sol";

interface ID4AProtocolSetter {
    event MintCapSet(
        bytes32 indexed daoId,
        uint32 daoMintCap,
        UserMintCapParam[] userMintCapParams,
        NftMinterCapInfo[] nftMinterCapInfo
    );

    event DaoPriceTemplateSet(bytes32 indexed daoId, PriceTemplateType priceTemplateType, uint256 nftPriceFactor);

    event CanvasRebateRatioInBpsSet(bytes32 indexed canvasId, uint256 newCanvasRebateRatioInBps);

    event DaoNftMaxSupplySet(bytes32 indexed daoId, uint256 newMaxSupply);

    event DaoMintableRoundSet(bytes32 daoId, uint256 newMintableRounds);

    event DaoFloorPriceSet(bytes32 daoId, uint256 newFloorPrice);

    event DaoTemplateSet(bytes32 daoId, TemplateParam templateParam);

    event DaoRatioSet(
        bytes32 daoId,
        uint256 daoCreatorERC20Ratio,
        uint256 canvasCreatorERC20Ratio,
        uint256 nftMinterERC20Ratio,
        uint256 daoFeePoolETHRatio,
        uint256 daoFeePoolETHRatioFlatPrice
    );

    event DailyMintCapSet(bytes32 indexed daoId, uint256 dailyMintCap);

    event DaoTokenSupplySet(bytes32 daoId, uint256 addedDaoToken);

    event WhiteListMintCapSet(bytes32 daoId, address whitelistUser, uint256 whitelistUserMintCap);

    function setMintCapAndPermission(
        bytes32 daoId,
        uint32 daoMintCap,
        UserMintCapParam[] calldata userMintCapParams,
        NftMinterCapInfo[] calldata nftMinterCapInfo,
        Whitelist memory whitelist,
        Blacklist memory blacklist,
        Blacklist memory unblacklist
    )
        external;

    function setDaoParams(SetDaoParam memory vars) external;

    function setDaoPriceTemplate(bytes32 daoId, PriceTemplateType priceTemplateType, uint256 priceFactor) external;

    function setDaoNftMaxSupply(bytes32 daoId, uint256 newMaxSupply) external;

    function setDaoMintableRound(bytes32 daoId, uint256 newMintableRound) external;

    function setDaoFloorPrice(bytes32 daoId, uint256 newFloorPrice) external;

    function setTemplate(bytes32 daoId, TemplateParam calldata templateParam) external;

    function setDailyMintCap(bytes32 daoId, uint256 dailyMintCap) external;

    function setDaoTokenSupply(bytes32 daoId, uint256 addedDaoToken) external;

    function setWhitelistMintCap(bytes32 daoId, address whitelistUser, uint32 whitelistUserMintCap) external;

    function setRatio(
        bytes32 daoId,
        uint256 daoCreatorERC20Ratio,
        uint256 canvasCreatorERC20Ratio,
        uint256 nftMinterERC20Ratio,
        uint256 daoFeePoolETHRatio,
        uint256 daoFeePoolETHRatioFlatPrice
    )
        external;

    function setCanvasRebateRatioInBps(bytes32 canvasId, uint256 newCanvasRebateRatioInBps) external payable;
}