// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./D4AStructs.sol";
import "./D4AEnums.sol";
import "./D4AErrors.sol";
import "./DaoStorage.sol";
import "./SettingsStorage.sol";
import "./BasicDaoStorage.sol";
import "./D4AProtocolReadable.sol";
import "./D4AProtocolSetter.sol";

contract PDProtocolSetter is D4AProtocolSetter {
    // 修改黑白名单方法
    function setMintCapAndPermission(
        bytes32 daoId,
        uint32 daoMintCap,
        UserMintCapParam[] calldata userMintCapParams,
        NftMinterCapInfo[] calldata nftMinterCapInfo,
        Whitelist memory whitelist,
        Blacklist memory blacklist,
        Blacklist memory unblacklist
    )
        public
        override
    {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        if (
            DaoStorage.layout().daoInfos[daoId].daoTag == DaoTag.BASIC_DAO && msg.sender != l.createProjectProxy
                && !BasicDaoStorage.layout().basicDaoInfos[daoId].unlocked
        ) {
            revert BasicDaoLocked();
        }

        super.setMintCapAndPermission(
            daoId, daoMintCap, userMintCapParams, nftMinterCapInfo, whitelist, blacklist, unblacklist
        );
    }

    // 修改Dao参数方法
    function setDaoParams(SetDaoParam memory vars) public override {
        if (
            DaoStorage.layout().daoInfos[vars.daoId].daoTag == DaoTag.BASIC_DAO
                && !BasicDaoStorage.layout().basicDaoInfos[vars.daoId].unlocked
        ) revert BasicDaoLocked();

        super.setDaoParams(vars);
    }

    function setDaoNftMaxSupply(bytes32 daoId, uint256 newMaxSupply) public override {
        if (
            DaoStorage.layout().daoInfos[daoId].daoTag == DaoTag.BASIC_DAO
                && !BasicDaoStorage.layout().basicDaoInfos[daoId].unlocked
        ) revert BasicDaoLocked();

        super.setDaoNftMaxSupply(daoId, newMaxSupply);
    }

    function setDaoMintableRound(bytes32 daoId, uint256 newMintableRound) public override {
        if (
            DaoStorage.layout().daoInfos[daoId].daoTag == DaoTag.BASIC_DAO
                && !BasicDaoStorage.layout().basicDaoInfos[daoId].unlocked
        ) revert BasicDaoLocked();

        super.setDaoMintableRound(daoId, newMintableRound);
    }

    function setDaoFloorPrice(bytes32 daoId, uint256 newFloorPrice) public override {
        if (
            DaoStorage.layout().daoInfos[daoId].daoTag == DaoTag.BASIC_DAO
                && !BasicDaoStorage.layout().basicDaoInfos[daoId].unlocked
        ) revert BasicDaoLocked();

        super.setDaoFloorPrice(daoId, newFloorPrice);
    }

    function setDaoPriceTemplate(
        bytes32 daoId,
        PriceTemplateType priceTemplateType,
        uint256 nftPriceFactor
    )
        public
        override
    {
        if (
            DaoStorage.layout().daoInfos[daoId].daoTag == DaoTag.BASIC_DAO
                && !BasicDaoStorage.layout().basicDaoInfos[daoId].unlocked
        ) revert BasicDaoLocked();

        super.setDaoPriceTemplate(daoId, priceTemplateType, nftPriceFactor);
    }

    function setTemplate(bytes32 daoId, TemplateParam calldata templateParam) public override {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        if (
            DaoStorage.layout().daoInfos[daoId].daoTag == DaoTag.BASIC_DAO && msg.sender != l.createProjectProxy
                && !BasicDaoStorage.layout().basicDaoInfos[daoId].unlocked
        ) {
            revert BasicDaoLocked();
        }

        super.setTemplate(daoId, templateParam);
    }

    function setRatio(
        bytes32 daoId,
        uint256 daoCreatorERC20Ratio,
        uint256 canvasCreatorERC20Ratio,
        uint256 nftMinterERC20Ratio,
        uint256 daoFeePoolETHRatio,
        uint256 daoFeePoolETHRatioFlatPrice
    )
        public
        override
    {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        if (
            DaoStorage.layout().daoInfos[daoId].daoTag == DaoTag.BASIC_DAO && msg.sender != l.createProjectProxy
                && !BasicDaoStorage.layout().basicDaoInfos[daoId].unlocked
        ) {
            revert BasicDaoLocked();
        }

        super.setRatio(
            daoId,
            daoCreatorERC20Ratio,
            canvasCreatorERC20Ratio,
            nftMinterERC20Ratio,
            daoFeePoolETHRatio,
            daoFeePoolETHRatioFlatPrice
        );
    }

    function setCanvasRebateRatioInBps(bytes32 canvasId, uint256 newCanvasRebateRatioInBps) public payable override {
        bytes32 daoId = D4AProtocolReadable(address(this)).getCanvasDaoId(canvasId);
        if (
            DaoStorage.layout().daoInfos[daoId].daoTag == DaoTag.BASIC_DAO
                && !BasicDaoStorage.layout().basicDaoInfos[daoId].unlocked
        ) revert BasicDaoLocked();

        super.setCanvasRebateRatioInBps(canvasId, newCanvasRebateRatioInBps);
    }

    function setDailyMintCap(bytes32 daoId, uint256 dailyMintCap) public override {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        if (
            DaoStorage.layout().daoInfos[daoId].daoTag == DaoTag.BASIC_DAO && msg.sender != l.createProjectProxy
                && !BasicDaoStorage.layout().basicDaoInfos[daoId].unlocked
        ) {
            revert BasicDaoLocked();
        }

        super.setDailyMintCap(daoId, dailyMintCap);
    }

    function setDaoTokenSupply(bytes32 daoId, uint256 addedDaoToken) public override {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        if (
            DaoStorage.layout().daoInfos[daoId].daoTag == DaoTag.BASIC_DAO && msg.sender != l.createProjectProxy
                && !BasicDaoStorage.layout().basicDaoInfos[daoId].unlocked
        ) {
            revert BasicDaoLocked();
        }
        super.setDaoTokenSupply(daoId, addedDaoToken);
    }

    function setWhitelistMintCap(bytes32 daoId, address whitelistUser, uint32 whitelistUserMintCap) public override {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        if (
            DaoStorage.layout().daoInfos[daoId].daoTag == DaoTag.BASIC_DAO && msg.sender != l.createProjectProxy
                && !BasicDaoStorage.layout().basicDaoInfos[daoId].unlocked
        ) {
            revert BasicDaoLocked();
        }
        super.setWhitelistMintCap(daoId, whitelistUser, whitelistUserMintCap);
    }
}