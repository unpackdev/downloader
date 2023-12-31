// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// external deps
import "./ReentrancyGuard.sol";
import "./LibString.sol";
import "./SafeTransferLib.sol";

// D4A constants, structs, enums && errors
import "./D4AConstants.sol";
import "./D4AStructs.sol";
import "./D4AEnums.sol";
import "./D4AErrors.sol";

// interfaces
import "./IPDCreate.sol";
import "./ID4AChangeAdmin.sol";

// D4A storages && contracts
import "./ProtocolStorage.sol";
import "./DaoStorage.sol";
import "./CanvasStorage.sol";
import "./PriceStorage.sol";
import "./SettingsStorage.sol";
import "./BasicDaoStorage.sol";
import "./D4AERC20.sol";
import "./D4AERC721.sol";
import "./D4AFeePool.sol";
import "./ProtocolChecker.sol";

contract PDCreate is IPDCreate, ProtocolChecker, ReentrancyGuard {
    struct CreateContinuousDaoParam {
        uint256 startRound;
        uint256 mintableRound;
        uint256 daoFloorPriceRank;
        uint256 nftMaxSupplyRank;
        uint96 royaltyFeeRatioInBps;
        uint256 daoIndex;
        string daoUri;
        uint256 initTokenSupplyRatio;
        string daoName;
        address tokenAddress;
        address feePoolAddress;
        bool needMintableWork;
        uint256 dailyMintCap;
    }

    function createBasicDao(
        DaoMetadataParam memory daoMetadataParam,
        BasicDaoParam memory basicDaoParam
    )
        public
        payable
        nonReentrant
        returns (bytes32 daoId)
    {
        _checkPauseStatus();
        _checkUriNotExist(daoMetadataParam.projectUri);
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        _checkCaller(l.createProjectProxy);
        ProtocolStorage.Layout storage protocolStorage = ProtocolStorage.layout();
        protocolStorage.uriExists[keccak256(abi.encodePacked(daoMetadataParam.projectUri))] = true;
        daoId = _createProject(
            daoMetadataParam.startDrb,
            daoMetadataParam.mintableRounds,
            daoMetadataParam.floorPriceRank,
            daoMetadataParam.maxNftRank,
            daoMetadataParam.royaltyFee,
            protocolStorage.lastestDaoIndexes[uint8(DaoTag.BASIC_DAO)],
            daoMetadataParam.projectUri,
            basicDaoParam.initTokenSupplyRatio,
            basicDaoParam.daoName
        );
        protocolStorage.daoIndexToIds[uint8(DaoTag.BASIC_DAO)][protocolStorage.lastestDaoIndexes[uint8(DaoTag.BASIC_DAO)]]
        = daoId;
        ++protocolStorage.lastestDaoIndexes[uint8(DaoTag.BASIC_DAO)];

        DaoStorage.Layout storage daoStorage = DaoStorage.layout();
        daoStorage.daoInfos[daoId].daoMintInfo.NFTHolderMintCap = 5;
        daoStorage.daoInfos[daoId].daoTag = DaoTag.BASIC_DAO;

        protocolStorage.uriExists[keccak256(abi.encodePacked(basicDaoParam.canvasUri))] = true;

        _createCanvas(
            CanvasStorage.layout().canvasInfos,
            daoId,
            basicDaoParam.canvasId,
            daoStorage.daoInfos[daoId].startRound,
            daoStorage.daoInfos[daoId].canvases.length,
            basicDaoParam.canvasUri,
            msg.sender
        );

        daoStorage.daoInfos[daoId].canvases.push(basicDaoParam.canvasId);
        BasicDaoStorage.Layout storage basicDaoStorage = BasicDaoStorage.layout();
        basicDaoStorage.basicDaoInfos[daoId].canvasIdOfSpecialNft = basicDaoParam.canvasId;
        basicDaoStorage.basicDaoInfos[daoId].dailyMintCap = 10_000;
    }

    function createOwnerBasicDao(
        DaoMetadataParam memory daoMetadataParam,
        BasicDaoParam memory basicDaoParam
    )
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
        if (((protocolStorage.basicDaoIndexBitMap >> daoMetadataParam.projectIndex) & 1) != 0) {
            revert DaoIndexAlreadyExist();
        }
        protocolStorage.basicDaoIndexBitMap |= (1 << daoMetadataParam.projectIndex);
        protocolStorage.uriExists[keccak256(abi.encodePacked(daoMetadataParam.projectUri))] = true;

        daoId = _createProject(
            daoMetadataParam.startDrb,
            daoMetadataParam.mintableRounds,
            daoMetadataParam.floorPriceRank,
            daoMetadataParam.maxNftRank,
            daoMetadataParam.royaltyFee,
            daoMetadataParam.projectIndex,
            daoMetadataParam.projectUri,
            basicDaoParam.initTokenSupplyRatio,
            basicDaoParam.daoName
        );
        protocolStorage.daoIndexToIds[uint8(DaoTag.BASIC_DAO)][daoMetadataParam.projectIndex] = daoId;

        DaoStorage.Layout storage daoStorage = DaoStorage.layout();
        daoStorage.daoInfos[daoId].daoMintInfo.NFTHolderMintCap = 5;
        daoStorage.daoInfos[daoId].daoTag = DaoTag.BASIC_DAO;

        protocolStorage.uriExists[keccak256(abi.encodePacked(basicDaoParam.canvasUri))] = true;

        _createCanvas(
            CanvasStorage.layout().canvasInfos,
            daoId,
            basicDaoParam.canvasId,
            daoStorage.daoInfos[daoId].startRound,
            daoStorage.daoInfos[daoId].canvases.length,
            basicDaoParam.canvasUri,
            msg.sender
        );

        daoStorage.daoInfos[daoId].canvases.push(basicDaoParam.canvasId);
        BasicDaoStorage.Layout storage basicDaoStorage = BasicDaoStorage.layout();
        basicDaoStorage.basicDaoInfos[daoId].canvasIdOfSpecialNft = basicDaoParam.canvasId;
        basicDaoStorage.basicDaoInfos[daoId].dailyMintCap = 10_000;
    }

    function createContinuousDao(
        bytes32 existDaoId,
        DaoMetadataParam memory daoMetadataParam,
        BasicDaoParam memory basicDaoParam,
        bool needMintableWork,
        uint256 dailyMintCap
    )
        public
        payable
        nonReentrant
        returns (bytes32 daoId)
    {
        // here need to check daoid if exist
        address feePoolAddress = DaoStorage.layout().daoInfos[existDaoId].daoFeePool;
        address tokenAddress = DaoStorage.layout().daoInfos[existDaoId].token;

        _checkPauseStatus();
        _checkUriNotExist(daoMetadataParam.projectUri);
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        _checkCaller(l.createProjectProxy);
        ProtocolStorage.Layout storage protocolStorage = ProtocolStorage.layout();
        protocolStorage.uriExists[keccak256(abi.encodePacked(daoMetadataParam.projectUri))] = true;

        CreateContinuousDaoParam memory createContinuousDaoParam;
        {
            createContinuousDaoParam.startRound = daoMetadataParam.startDrb;
            createContinuousDaoParam.mintableRound = daoMetadataParam.mintableRounds;
            createContinuousDaoParam.daoFloorPriceRank = daoMetadataParam.floorPriceRank;
            createContinuousDaoParam.nftMaxSupplyRank = daoMetadataParam.maxNftRank;
            createContinuousDaoParam.royaltyFeeRatioInBps = daoMetadataParam.royaltyFee;
            createContinuousDaoParam.daoIndex = protocolStorage.lastestDaoIndexes[uint8(DaoTag.BASIC_DAO)];
            createContinuousDaoParam.daoUri = daoMetadataParam.projectUri;
            createContinuousDaoParam.initTokenSupplyRatio = basicDaoParam.initTokenSupplyRatio;
            createContinuousDaoParam.daoName = basicDaoParam.daoName;
            createContinuousDaoParam.tokenAddress = tokenAddress;
            createContinuousDaoParam.feePoolAddress = feePoolAddress;
            createContinuousDaoParam.needMintableWork = needMintableWork;
            createContinuousDaoParam.dailyMintCap = dailyMintCap;
        }
        daoId = _createContinuousProject(createContinuousDaoParam);

        protocolStorage.daoIndexToIds[uint8(DaoTag.BASIC_DAO)][protocolStorage.lastestDaoIndexes[uint8(DaoTag.BASIC_DAO)]]
        = daoId;
        ++protocolStorage.lastestDaoIndexes[uint8(DaoTag.BASIC_DAO)];

        DaoStorage.Layout storage daoStorage = DaoStorage.layout();
        //daoStorage.daoInfos[daoId].daoMintInfo.NFTHolderMintCap = 5;
        daoStorage.daoInfos[daoId].daoTag = DaoTag.BASIC_DAO;

        protocolStorage.uriExists[keccak256(abi.encodePacked(basicDaoParam.canvasUri))] = true;

        _createCanvas(
            CanvasStorage.layout().canvasInfos,
            daoId,
            basicDaoParam.canvasId,
            daoStorage.daoInfos[daoId].startRound,
            daoStorage.daoInfos[daoId].canvases.length,
            basicDaoParam.canvasUri,
            msg.sender
        );

        daoStorage.daoInfos[daoId].canvases.push(basicDaoParam.canvasId);
        BasicDaoStorage.Layout storage basicDaoStorage = BasicDaoStorage.layout();
        basicDaoStorage.basicDaoInfos[daoId].canvasIdOfSpecialNft = basicDaoParam.canvasId;
        // dailyMintCap
        basicDaoStorage.basicDaoInfos[daoId].dailyMintCap = dailyMintCap;
    }

    function createCanvas(
        bytes32 daoId,
        bytes32 canvasId,
        string calldata canvasUri,
        bytes32[] calldata proof,
        address to
    )
        external
        payable
        nonReentrant
    {
        _checkPauseStatus();
        _checkDaoExist(daoId);
        _checkPauseStatus(daoId);
        _checkUriNotExist(canvasUri);

        SettingsStorage.Layout storage l = SettingsStorage.layout();
        if (l.permissionControl.isCanvasCreatorBlacklisted(daoId, to)) revert Blacklisted();
        if (!l.permissionControl.inCanvasCreatorWhitelist(daoId, to, proof)) {
            revert NotInWhitelist();
        }

        ProtocolStorage.layout().uriExists[keccak256(abi.encodePacked(canvasUri))] = true;

        _createCanvas(
            CanvasStorage.layout().canvasInfos,
            daoId,
            canvasId,
            DaoStorage.layout().daoInfos[daoId].startRound,
            DaoStorage.layout().daoInfos[daoId].canvases.length,
            canvasUri,
            to
        );

        DaoStorage.layout().daoInfos[daoId].canvases.push(canvasId);
    }

    function _createProject(
        uint256 startRound,
        uint256 mintableRound,
        uint256 daoFloorPriceRank,
        uint256 nftMaxSupplyRank,
        uint96 royaltyFeeRatioInBps,
        uint256 daoIndex,
        string memory daoUri,
        uint256 initTokenSupplyRatio,
        string memory daoName
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
            daoInfo.token = _createERC20Token(daoIndex, daoName);

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

            bool needMintableWork = true;
            daoInfo.nft = _createERC721Token(daoIndex, daoName, needMintableWork);
            D4AERC721(daoInfo.nft).grantRole(keccak256("ROYALTY"), msg.sender);
            D4AERC721(daoInfo.nft).grantRole(keccak256("MINTER"), address(this));

            D4AERC721(daoInfo.nft).setContractUri(daoUri);
            ID4AChangeAdmin(daoInfo.nft).changeAdmin(l.assetOwner);
            ID4AChangeAdmin(daoInfo.nft).transferOwnership(msg.sender);
            //We copy from setting in case setting may change later.
            daoInfo.tokenMaxSupply = (l.tokenMaxSupply * initTokenSupplyRatio) / BASIS_POINT;

            if (daoFloorPriceRank != 9999) {
                // 9999 is specified for 0 floor price
                PriceStorage.layout().daoFloorPrices[daoId] = l.daoFloorPrices[daoFloorPriceRank];
            }

            daoInfo.daoExist = true;
            emit NewProject(daoId, daoUri, daoFeePool, daoInfo.token, daoInfo.nft, royaltyFeeRatioInBps);
        }
    }

    function _createContinuousProject(CreateContinuousDaoParam memory createContinuousDaoParam)
        internal
        returns (bytes32 daoId)
    {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        if (createContinuousDaoParam.mintableRound > l.maxMintableRound) revert ExceedMaxMintableRound();
        {
            uint256 protocolRoyaltyFeeRatioInBps = l.protocolRoyaltyFeeRatioInBps;
            if (
                createContinuousDaoParam.royaltyFeeRatioInBps < l.minRoyaltyFeeRatioInBps + protocolRoyaltyFeeRatioInBps
                    || createContinuousDaoParam.royaltyFeeRatioInBps
                        > l.maxRoyaltyFeeRatioInBps + protocolRoyaltyFeeRatioInBps
            ) revert RoyaltyFeeRatioOutOfRange();
        }

        daoId = keccak256(abi.encodePacked(block.number, msg.sender, msg.data, tx.origin));
        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];

        if (daoInfo.daoExist) revert D4AProjectAlreadyExist(daoId);
        {
            if (createContinuousDaoParam.startRound < l.drb.currentRound()) revert StartRoundAlreadyPassed();
            daoInfo.startRound = createContinuousDaoParam.startRound;
            daoInfo.mintableRound = createContinuousDaoParam.mintableRound;
            daoInfo.nftMaxSupply = l.nftMaxSupplies[createContinuousDaoParam.nftMaxSupplyRank];
            daoInfo.daoUri = createContinuousDaoParam.daoUri;
            daoInfo.royaltyFeeRatioInBps = createContinuousDaoParam.royaltyFeeRatioInBps;
            daoInfo.daoIndex = createContinuousDaoParam.daoIndex;
            daoInfo.token = createContinuousDaoParam.tokenAddress;

            address daoFeePool = createContinuousDaoParam.feePoolAddress;

            daoInfo.daoFeePool = daoFeePool;

            l.ownerProxy.initOwnerOf(daoId, msg.sender);

            daoInfo.nft = _createERC721Token(
                createContinuousDaoParam.daoIndex,
                createContinuousDaoParam.daoName,
                createContinuousDaoParam.needMintableWork
            );

            D4AERC721(daoInfo.nft).grantRole(keccak256("ROYALTY"), msg.sender);
            D4AERC721(daoInfo.nft).grantRole(keccak256("MINTER"), address(this));

            D4AERC721(daoInfo.nft).setContractUri(createContinuousDaoParam.daoUri);
            ID4AChangeAdmin(daoInfo.nft).changeAdmin(l.assetOwner);
            ID4AChangeAdmin(daoInfo.nft).transferOwnership(msg.sender);
            //We copy from setting in case setting may change later.
            daoInfo.tokenMaxSupply = (l.tokenMaxSupply * createContinuousDaoParam.initTokenSupplyRatio) / BASIS_POINT;

            if (createContinuousDaoParam.daoFloorPriceRank != 9999) {
                // 9999 is specified for 0 floor price
                PriceStorage.layout().daoFloorPrices[daoId] =
                    l.daoFloorPrices[createContinuousDaoParam.daoFloorPriceRank];
            }

            daoInfo.daoExist = true;
            emit NewProject(
                daoId,
                createContinuousDaoParam.daoUri,
                daoFeePool,
                daoInfo.token,
                daoInfo.nft,
                createContinuousDaoParam.royaltyFeeRatioInBps
            );
        }
    }

    function _createERC20Token(uint256 daoIndex, string memory daoName) internal returns (address) {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        string memory name = daoName;
        string memory sym = string(abi.encodePacked("PDAO.T", LibString.toString(daoIndex)));
        return l.erc20Factory.createD4AERC20(name, sym, address(this));
    }

    function _createERC721Token(
        uint256 daoIndex,
        string memory daoName,
        bool needMintableWork
    )
        internal
        returns (address)
    {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        string memory name = daoName;
        string memory sym = string(abi.encodePacked("PDAO.N", LibString.toString(daoIndex)));
        if (needMintableWork) {
            return l.erc721Factory.createD4AERC721(name, sym, BASIC_DAO_RESERVE_NFT_NUMBER);
        } else {
            return l.erc721Factory.createD4AERC721(name, sym, 0);
        }
    }

    function _createCanvas(
        mapping(bytes32 => CanvasStorage.CanvasInfo) storage canvasInfos,
        bytes32 daoId,
        bytes32 canvasId,
        uint256 daoStartRound,
        uint256 canvasIndex,
        string memory canvasUri,
        address to
    )
        internal
    {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        if (canvasInfos[canvasId].canvasExist) revert D4ACanvasAlreadyExist(canvasId);

        {
            CanvasStorage.CanvasInfo storage canvasInfo = canvasInfos[canvasId];
            canvasInfo.daoId = daoId;
            canvasInfo.canvasUri = canvasUri;
            canvasInfo.index = canvasIndex + 1;
            l.ownerProxy.initOwnerOf(canvasId, to);
            canvasInfo.canvasExist = true;
        }
        emit NewCanvas(daoId, canvasId, canvasUri);
    }
}