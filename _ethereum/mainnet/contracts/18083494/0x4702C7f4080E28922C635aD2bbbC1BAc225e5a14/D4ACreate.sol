// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ReentrancyGuard.sol";
import "./LibString.sol";
import "./SafeTransferLib.sol";

import "./D4AStructs.sol";
import "./D4AEnums.sol";
import "./D4AErrors.sol";
import "./ProtocolStorage.sol";
import "./DaoStorage.sol";
import "./CanvasStorage.sol";
import "./SettingsStorage.sol";
import "./PriceStorage.sol";
import "./ID4ACreate.sol";
import "./ID4AChangeAdmin.sol";
import "./ID4AProtocolSetter.sol";
import "./ProtocolChecker.sol";
import "./D4AERC20.sol";
import "./D4AERC721.sol";
import "./D4AFeePool.sol";

contract D4ACreate is ID4ACreate, ProtocolChecker, ReentrancyGuard {
    function createProject(
        uint256 startRound,
        uint256 mintableRound,
        uint256 daoFloorPriceRank,
        uint256 nftMaxSupplyRank,
        uint96 royaltyFeeRatioInBps,
        string calldata daoUri
    )
        public
        payable
        nonReentrant
        returns (bytes32 daoId)
    {
        _checkPauseStatus();
        _checkUriNotExist(daoUri);
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        _checkCaller(l.createProjectProxy);
        ProtocolStorage.Layout storage protocolStorage = ProtocolStorage.layout();
        protocolStorage.uriExists[keccak256(abi.encodePacked(daoUri))] = true;
        daoId = _createProject(
            startRound,
            mintableRound,
            daoFloorPriceRank,
            nftMaxSupplyRank,
            royaltyFeeRatioInBps,
            protocolStorage.lastestDaoIndexes[uint8(DaoTag.D4A_DAO)],
            daoUri
        );
        protocolStorage.daoIndexToIds[uint8(DaoTag.D4A_DAO)][protocolStorage.lastestDaoIndexes[uint8(DaoTag.D4A_DAO)]] =
            daoId;
        ++protocolStorage.lastestDaoIndexes[uint8(DaoTag.D4A_DAO)];
    }

    function createOwnerProject(DaoMetadataParam calldata daoMetadataParam)
        public
        payable
        nonReentrant
        returns (bytes32 daoId)
    {
        _checkPauseStatus();

        SettingsStorage.Layout storage l = SettingsStorage.layout();
        _checkCaller(l.createProjectProxy);
        _checkUriNotExist(daoMetadataParam.projectUri);
        if (daoMetadataParam.projectIndex >= l.reservedDaoAmount) revert DaoIndexTooLarge();

        ProtocolStorage.Layout storage protocolStorage = ProtocolStorage.layout();
        if (((protocolStorage.d4aDaoIndexBitMap >> daoMetadataParam.projectIndex) & 1) != 0) {
            revert DaoIndexAlreadyExist();
        }
        protocolStorage.d4aDaoIndexBitMap |= (1 << daoMetadataParam.projectIndex);
        protocolStorage.uriExists[keccak256(abi.encodePacked(daoMetadataParam.projectUri))] = true;

        daoId = _createProject(
            daoMetadataParam.startDrb,
            daoMetadataParam.mintableRounds,
            daoMetadataParam.floorPriceRank,
            daoMetadataParam.maxNftRank,
            daoMetadataParam.royaltyFee,
            daoMetadataParam.projectIndex,
            daoMetadataParam.projectUri
        );
        protocolStorage.daoIndexToIds[uint8(DaoTag.D4A_DAO)][daoMetadataParam.projectIndex] = daoId;
    }

    function createCanvas(
        bytes32 daoId,
        string calldata canvasUri,
        bytes32[] calldata proof,
        uint256 canvasRebateRatioInBps
    )
        external
        payable
        nonReentrant
        returns (bytes32)
    {
        _checkPauseStatus();
        _checkDaoExist(daoId);
        _checkPauseStatus(daoId);
        _checkUriNotExist(canvasUri);

        SettingsStorage.Layout storage l = SettingsStorage.layout();
        if (l.permissionControl.isCanvasCreatorBlacklisted(daoId, msg.sender)) revert Blacklisted();
        if (!l.permissionControl.inCanvasCreatorWhitelist(daoId, msg.sender, proof)) {
            revert NotInWhitelist();
        }

        ProtocolStorage.layout().uriExists[keccak256(abi.encodePacked(canvasUri))] = true;

        bytes32 canvasId = _createCanvas(
            CanvasStorage.layout().canvasInfos,
            DaoStorage.layout().daoInfos[daoId].daoFeePool,
            daoId,
            DaoStorage.layout().daoInfos[daoId].startRound,
            DaoStorage.layout().daoInfos[daoId].canvases.length,
            canvasUri
        );

        DaoStorage.layout().daoInfos[daoId].canvases.push(canvasId);

        (bool succ,) = address(this).delegatecall(
            abi.encodeWithSelector(
                ID4AProtocolSetter.setCanvasRebateRatioInBps.selector, canvasId, canvasRebateRatioInBps
            )
        );
        require(succ);

        return canvasId;
    }

    function _createProject(
        uint256 startRound,
        uint256 mintableRound,
        uint256 daoFloorPriceRank,
        uint256 nftMaxSupplyRank,
        uint96 royaltyFeeRatioInBps,
        uint256 daoIndex,
        string memory daoUri
    )
        internal
        returns (bytes32 daoId)
    {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        if (mintableRound > l.maxMintableRound) revert ExceedMaxMintableRound();
        {
            uint256 protocolRoyaltyFeeRatioInBps = l.protocolRoyaltyFeeRatioInBps;
            if (
                royaltyFeeRatioInBps < l.minRoyaltyFeeRatioInBps + protocolRoyaltyFeeRatioInBps
                    || royaltyFeeRatioInBps > l.maxRoyaltyFeeRatioInBps + protocolRoyaltyFeeRatioInBps
            ) revert RoyaltyFeeRatioOutOfRange();
        }
        {
            uint256 createDaoFeeAmount = l.createDaoFeeAmount;
            if (msg.value < createDaoFeeAmount) revert NotEnoughEther();

            SafeTransferLib.safeTransferETH(l.protocolFeePool, createDaoFeeAmount);
            uint256 exchange = msg.value - createDaoFeeAmount;
            if (exchange > 0) SafeTransferLib.safeTransferETH(msg.sender, exchange);
        }

        daoId = keccak256(abi.encodePacked(block.number, msg.sender, msg.data, tx.origin));
        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];

        if (daoInfo.daoExist) revert D4AProjectAlreadyExist(daoId);
        {
            if (startRound < l.drb.currentRound()) revert StartRoundAlreadyPassed();
            daoInfo.startRound = startRound;
            daoInfo.mintableRound = mintableRound;
            daoInfo.nftMaxSupply = l.nftMaxSupplies[nftMaxSupplyRank];
            daoInfo.daoUri = daoUri;
            daoInfo.royaltyFeeRatioInBps = royaltyFeeRatioInBps;
            daoInfo.daoIndex = daoIndex;
            daoInfo.token = _createERC20Token(daoIndex);

            D4AERC20(daoInfo.token).grantRole(keccak256("MINTER"), address(this));
            D4AERC20(daoInfo.token).grantRole(keccak256("BURNER"), address(this));

            address daoFeePool = l.feePoolFactory.createD4AFeePool(
                string(abi.encodePacked("Asset Pool for DAO4Art Project ", LibString.toString(daoIndex)))
            );

            D4AFeePool(payable(daoFeePool)).grantRole(keccak256("AUTO_TRANSFER"), address(this));

            ID4AChangeAdmin(daoFeePool).changeAdmin(l.assetOwner);
            ID4AChangeAdmin(daoInfo.token).changeAdmin(l.assetOwner);

            daoInfo.daoFeePool = daoFeePool;

            l.ownerProxy.initOwnerOf(daoId, msg.sender);

            daoInfo.nft = _createERC721Token(daoIndex);
            D4AERC721(daoInfo.nft).grantRole(keccak256("ROYALTY"), msg.sender);
            D4AERC721(daoInfo.nft).grantRole(keccak256("MINTER"), address(this));

            D4AERC721(daoInfo.nft).setContractUri(daoUri);
            ID4AChangeAdmin(daoInfo.nft).changeAdmin(l.assetOwner);
            ID4AChangeAdmin(daoInfo.nft).transferOwnership(msg.sender);
            //We copy from setting in case setting may change later.
            daoInfo.tokenMaxSupply = l.tokenMaxSupply;

            if (daoFloorPriceRank != 9999) {
                // 9999 is specified for 0 floor price
                PriceStorage.layout().daoFloorPrices[daoId] = l.daoFloorPrices[daoFloorPriceRank];
            }

            daoInfo.daoExist = true;
            emit NewProject(daoId, daoUri, daoFeePool, daoInfo.token, daoInfo.nft, royaltyFeeRatioInBps);
        }
    }

    function _createERC20Token(uint256 daoIndex) internal returns (address) {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        string memory name = string(abi.encodePacked("D4A Token for No.", LibString.toString(daoIndex)));
        string memory sym = string(abi.encodePacked("D4A.T", LibString.toString(daoIndex)));
        return l.erc20Factory.createD4AERC20(name, sym, address(this));
    }

    function _createERC721Token(uint256 daoIndex) internal returns (address) {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        string memory name = string(abi.encodePacked("D4A NFT for No.", LibString.toString(daoIndex)));
        string memory sym = string(abi.encodePacked("D4A.N", LibString.toString(daoIndex)));
        return l.erc721Factory.createD4AERC721(name, sym, 0);
    }

    function _createCanvas(
        mapping(bytes32 => CanvasStorage.CanvasInfo) storage canvasInfos,
        address daoFeePool,
        bytes32 daoId,
        uint256 daoStartRound,
        uint256 canvasIndex,
        string memory canvasUri
    )
        internal
        returns (bytes32)
    {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        {
            uint256 cur_round = l.drb.currentRound();
            if (cur_round < daoStartRound) revert DaoNotStarted();
        }

        {
            uint256 createCanvasFeeAmount = l.createCanvasFeeAmount;
            if (msg.value < createCanvasFeeAmount) revert NotEnoughEther();

            SafeTransferLib.safeTransferETH(daoFeePool, createCanvasFeeAmount);

            uint256 exchange = msg.value - createCanvasFeeAmount;
            if (exchange > 0) SafeTransferLib.safeTransferETH(msg.sender, exchange);
        }
        bytes32 canvasId = keccak256(abi.encodePacked(block.number, msg.sender, msg.data, tx.origin));
        if (canvasInfos[canvasId].canvasExist) revert D4ACanvasAlreadyExist(canvasId);

        {
            CanvasStorage.CanvasInfo storage canvasInfo = canvasInfos[canvasId];
            canvasInfo.daoId = daoId;
            canvasInfo.canvasUri = canvasUri;
            canvasInfo.index = canvasIndex + 1;
            l.ownerProxy.initOwnerOf(canvasId, msg.sender);
            canvasInfo.canvasExist = true;
        }
        emit NewCanvas(daoId, canvasId, canvasUri);
        return canvasId;
    }
}
