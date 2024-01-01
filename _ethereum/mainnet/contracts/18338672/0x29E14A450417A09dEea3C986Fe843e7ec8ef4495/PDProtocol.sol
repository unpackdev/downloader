// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

// external deps
import "./IAccessControlUpgradeable.sol";
import "./IERC20.sol";
import "./Initializable.sol";
import "./ReentrancyGuard.sol";
import "./ECDSAUpgradeable.sol";
import "./EIP712.sol";
import "./IERC721Upgradeable.sol";
import "./SafeTransferLib.sol";
import "./LibString.sol";
import "./Multicallable.sol";

// D4A constants, structs, enums && errors
import "./D4AConstants.sol";
import "./D4AStructs.sol";
import "./D4AEnums.sol";
import "./D4AErrors.sol";

// interfaces
import "./IPriceTemplate.sol";
import "./IRewardTemplate.sol";
import "./IPermissionControl.sol";
import "./ID4AProtocolReadable.sol";
import "./IPDProtocol.sol";
import "./IPDCreate.sol";

// D4A storages && contracts
import "./ProtocolStorage.sol";
import "./DaoStorage.sol";
import "./CanvasStorage.sol";
import "./PriceStorage.sol";
import "./RewardStorage.sol";
import "./SettingsStorage.sol";
import "./GrantStorage.sol";
import "./BasicDaoStorage.sol";
import "./D4AERC20.sol";
import "./D4AERC721.sol";
import "./D4AFeePool.sol";
import "./D4AVestingWallet.sol";
import "./ProtocolChecker.sol";

//import "./Test.sol";

contract PDProtocol is IPDProtocol, ProtocolChecker, Initializable, Multicallable, ReentrancyGuard, EIP712 {
    using LibString for string;

    bytes32 internal constant _MINTNFT_TYPEHASH =
        keccak256("MintNFT(bytes32 canvasID,bytes32 tokenURIHash,uint256 flatPrice)");

    function initialize() public reinitializer(4) {
        uint256 reservedDaoAmount = SettingsStorage.layout().reservedDaoAmount;
        ProtocolStorage.Layout storage protocolStorage = ProtocolStorage.layout();
        protocolStorage.lastestDaoIndexes[uint8(DaoTag.D4A_DAO)] = reservedDaoAmount;
        protocolStorage.lastestDaoIndexes[uint8(DaoTag.BASIC_DAO)] = reservedDaoAmount;
    }

    function createCanvasAndMintNFT(
        bytes32 daoId,
        bytes32 canvasId,
        string memory canvasUri,
        address to,
        string calldata tokenUri,
        bytes calldata signature,
        uint256 flatPrice,
        bytes32[] calldata proof,
        address nftOwner
    )
        external
        payable
        returns (uint256)
    {
        _createCanvas(daoId, canvasId, canvasUri, to);
        return _mintNFTAndTransfer(daoId, canvasId, tokenUri, proof, flatPrice, signature, nftOwner);
    }

    function _createCanvas(bytes32 daoId, bytes32 canvasId, string memory canvasUri, address to) internal {
        (bool succ,) = address(this).delegatecall(
            abi.encodeCall(IPDCreate.createCanvas, (daoId, canvasId, canvasUri, new bytes32[](0), to))
        );
        if (!succ) {
            /// @solidity memory-safe-assembly
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function mintNFT(
        bytes32 daoId,
        bytes32 canvasId,
        string calldata tokenUri,
        bytes32[] calldata proof,
        uint256 flatPrice,
        bytes calldata signature
    )
        external
        payable
        nonReentrant
        returns (uint256)
    {
        return _mintNFTAndTransfer(daoId, canvasId, tokenUri, proof, flatPrice, signature, msg.sender);
    }

    function mintNFTAndTransfer(
        bytes32 daoId,
        bytes32 canvasId,
        string calldata tokenUri,
        bytes32[] calldata proof,
        uint256 flatPrice,
        bytes calldata signature,
        address to
    )
        external
        payable
        nonReentrant
        returns (uint256 tokenId)
    {
        return _mintNFTAndTransfer(daoId, canvasId, tokenUri, proof, flatPrice, signature, to);
    }

    function _mintNFTAndTransfer(
        bytes32 daoId,
        bytes32 canvasId,
        string calldata tokenUri,
        bytes32[] calldata proof,
        uint256 flatPrice,
        bytes calldata signature,
        address to
    )
        internal
        returns (uint256 tokenId)
    {
        BasicDaoStorage.BasicDaoInfo storage basicDaoInfo = BasicDaoStorage.layout().basicDaoInfos[daoId];
        if (DaoStorage.layout().daoInfos[daoId].daoTag == DaoTag.BASIC_DAO && !basicDaoInfo.unifiedPriceModeOff) {
            if (flatPrice != ID4AProtocolReadable(address(this)).getDaoUnifiedPrice(daoId)) {
                revert NotBasicDaoNftFlatPrice();
            }
        } else {
            _verifySignature(daoId, canvasId, tokenUri, flatPrice, signature);
        }
        _checkMintEligibility(daoId, msg.sender, proof, 1);
        DaoStorage.layout().daoInfos[daoId].daoMintInfo.userMintInfos[msg.sender].minted += 1;
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        DaoStorage.layout().daoInfos[daoId].dailyMint[l.drb.currentRound()] += 1;
        tokenId = _mintNft(daoId, canvasId, tokenUri, flatPrice, to);
    }

    function batchMint(
        bytes32 daoId,
        bytes32 canvasId,
        bytes32[] calldata proof,
        MintNftInfo[] calldata mintNftInfos,
        bytes[] calldata signatures
    )
        external
        payable
        nonReentrant
        returns (uint256[] memory)
    {
        uint256 length = mintNftInfos.length;
        {
            _checkMintEligibility(daoId, msg.sender, proof, length);
            for (uint256 i; i < length;) {
                _verifySignature(daoId, canvasId, mintNftInfos[i].tokenUri, mintNftInfos[i].flatPrice, signatures[i]);
                unchecked {
                    ++i;
                }
            }
        }
        DaoStorage.layout().daoInfos[daoId].daoMintInfo.userMintInfos[msg.sender].minted += uint32(length);
        return _batchMint(daoId, canvasId, mintNftInfos);
        // uint256[] memory ret = new uint256[](0);
        // return ret;
    }

    function _batchMint(
        bytes32 daoId,
        bytes32 canvasId,
        MintNftInfo[] memory mintNftInfos
    )
        internal
        returns (uint256[] memory)
    {
        _checkPauseStatus();
        _checkPauseStatus(daoId);
        _checkCanvasExist(canvasId);
        _checkPauseStatus(canvasId);

        BatchMintLocalVars memory vars;
        vars.length = mintNftInfos.length;
        BasicDaoStorage.BasicDaoInfo storage basicDaoInfo = BasicDaoStorage.layout().basicDaoInfos[daoId];
        uint256[] memory tokenIds = new uint256[](vars.length);
        for (uint256 i; i < vars.length;) {
            _checkUriNotExist(mintNftInfos[i].tokenUri);
            if (_isSpecialTokenUri(daoId, mintNftInfos[i].tokenUri)) {
                ++basicDaoInfo.tokenId;
                if (canvasId != BasicDaoStorage.layout().basicDaoInfos[daoId].canvasIdOfSpecialNft) {
                    revert NotCanvasIdOfSpecialTokenUri();
                }
                if (mintNftInfos[i].flatPrice != BasicDaoStorage.layout().basicDaoNftFlatPrice) {
                    revert NotBasicDaoNftFlatPrice();
                }
                mintNftInfos[i].tokenUri = _fetchRightTokenUri(daoId, basicDaoInfo.tokenId);
                tokenIds[i] = basicDaoInfo.tokenId;
            }
            unchecked {
                ++i;
            }
        }

        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        CanvasStorage.CanvasInfo storage canvasInfo = CanvasStorage.layout().canvasInfos[canvasId];
        if (daoInfo.nftTotalSupply + vars.length > daoInfo.nftMaxSupply) revert NftExceedMaxAmount();

        vars.currentRound = SettingsStorage.layout().drb.currentRound();
        vars.nftPriceFactor = daoInfo.nftPriceFactor;

        daoInfo.nftTotalSupply += vars.length;
        for (uint256 i; i < vars.length;) {
            ProtocolStorage.layout().uriExists[keccak256(abi.encodePacked(mintNftInfos[i].tokenUri))] = true;
            tokenIds[i] = D4AERC721(daoInfo.nft).mintItem(msg.sender, mintNftInfos[i].tokenUri, tokenIds[i]);
            canvasInfo.tokenIds.push(tokenIds[i]);
            ProtocolStorage.layout().nftHashToCanvasId[keccak256(abi.encodePacked(daoId, tokenIds[i]))] = canvasId;
            uint256 flatPrice = mintNftInfos[i].flatPrice;
            if (flatPrice == 0) {
                uint256 price =
                    _getCanvasNextPrice(daoId, canvasId, 0, daoInfo.startRound, vars.currentRound, vars.nftPriceFactor);
                vars.daoTotalShare += ID4AProtocolReadable(address(this)).getDaoFeePoolETHRatio(daoId) * price;
                vars.totalPrice += price;
                emit D4AMintNFT(daoId, canvasId, tokenIds[i], mintNftInfos[i].tokenUri, price);
                _updatePrice(vars.currentRound, daoId, canvasId, price, 0, vars.nftPriceFactor);
            } else {
                vars.daoTotalShare +=
                    ID4AProtocolReadable(address(this)).getDaoFeePoolETHRatioFlatPrice(daoId) * flatPrice;
                vars.totalPrice += flatPrice;
                emit D4AMintNFT(daoId, canvasId, tokenIds[i], mintNftInfos[i].tokenUri, flatPrice);
            }
            unchecked {
                ++i;
            }
        }

        SettingsStorage.Layout storage l = SettingsStorage.layout();
        uint256 canvasRebateRatioInBps;
        if (
            vars.totalPrice - vars.daoTotalShare / BASIS_POINT
                - (vars.totalPrice * l.protocolMintFeeRatioInBps) / BASIS_POINT != 0
                && ID4AProtocolReadable(address(this)).getNftMinterERC20Ratio(daoId) != 0
        ) canvasRebateRatioInBps = canvasInfo.canvasRebateRatioInBps;
        uint256 daoFee = _splitFee(
            l.protocolFeePool,
            daoInfo.daoFeePool,
            l.ownerProxy.ownerOf(canvasId),
            vars.totalPrice,
            vars.daoTotalShare,
            canvasRebateRatioInBps
        );

        bytes32 tempDaoId = daoId;
        _updateReward(
            daoId,
            canvasId,
            PriceStorage.layout().daoFloorPrices[tempDaoId] == 0 ? 1 ether * vars.length : daoFee,
            canvasRebateRatioInBps
        );

        return tokenIds;
    }

    function claimProjectERC20Reward(bytes32 daoId) public nonReentrant returns (uint256 daoCreatorReward) {
        _checkPauseStatus();
        _checkPauseStatus(daoId);
        _checkDaoExist(daoId);
        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        (bool succ, bytes memory data) = l.rewardTemplates[uint8(daoInfo.rewardTemplateType)].delegatecall(
            abi.encodeWithSelector(
                IRewardTemplate.claimDaoCreatorReward.selector,
                daoId,
                l.protocolFeePool,
                l.ownerProxy.ownerOf(daoId),
                l.drb.currentRound(),
                daoInfo.token
            )
        );
        require(succ);
        (, daoCreatorReward) = abi.decode(data, (uint256, uint256));

        emit D4AClaimProjectERC20Reward(daoId, daoInfo.token, daoCreatorReward);
    }

    function claimCanvasReward(bytes32 canvasId) public nonReentrant returns (uint256) {
        _checkPauseStatus();
        _checkPauseStatus(canvasId);
        _checkCanvasExist(canvasId);
        bytes32 daoId = CanvasStorage.layout().canvasInfos[canvasId].daoId;
        _checkDaoExist(daoId);
        _checkPauseStatus(daoId);

        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        (bool succ, bytes memory data) = l.rewardTemplates[uint8(daoInfo.rewardTemplateType)].delegatecall(
            abi.encodeWithSelector(
                IRewardTemplate.claimCanvasCreatorReward.selector,
                daoId,
                canvasId,
                l.ownerProxy.ownerOf(canvasId),
                l.drb.currentRound(),
                daoInfo.token
            )
        );
        require(succ);
        uint256 amount = abi.decode(data, (uint256));

        emit D4AClaimCanvasReward(daoId, canvasId, daoInfo.token, amount);

        return amount;
    }

    function claimNftMinterReward(bytes32 daoId, address minter) public nonReentrant returns (uint256) {
        _checkPauseStatus();
        _checkDaoExist(daoId);
        _checkPauseStatus(daoId);
        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        (bool succ, bytes memory data) = l.rewardTemplates[uint8(daoInfo.rewardTemplateType)].delegatecall(
            abi.encodeWithSelector(
                IRewardTemplate.claimNftMinterReward.selector, daoId, minter, l.drb.currentRound(), daoInfo.token
            )
        );
        require(succ);
        uint256 amount = abi.decode(data, (uint256));

        emit D4AClaimNftMinterReward(daoId, daoInfo.token, amount);

        return amount;
    }

    struct ExchangeERC20ToETHLocalVars {
        uint256 tokenCirculation;
        uint256 tokenAmount;
    }

    function exchangeERC20ToETH(bytes32 daoId, uint256 tokenAmount, address to) public nonReentrant returns (uint256) {
        _checkPauseStatus();
        _checkPauseStatus(daoId);

        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        address token = daoInfo.token;
        address daoFeePool = daoInfo.daoFeePool;

        D4AERC20(token).burn(msg.sender, tokenAmount);
        D4AERC20(token).mint(daoFeePool, tokenAmount);

        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];
        if (rewardInfo.rewardIssuePendingRound != 0) {
            uint256 roundReward =
                ID4AProtocolReadable(address(this)).getRoundReward(daoId, rewardInfo.rewardIssuePendingRound);
            rewardInfo.rewardIssuePendingRound = 0;
            D4AERC20(token).mint(address(this), roundReward);
        }

        ExchangeERC20ToETHLocalVars memory vars;
        vars.tokenCirculation = D4AERC20(token).totalSupply() + tokenAmount - D4AERC20(token).balanceOf(daoFeePool);

        if (vars.tokenCirculation == 0) return 0;

        GrantStorage.Layout storage grantStorage = GrantStorage.layout();
        D4AVestingWallet vestingWallet = D4AVestingWallet(payable(grantStorage.vestingWallets[daoId]));
        vars.tokenAmount = tokenAmount;
        if (address(vestingWallet) != address(0)) {
            vestingWallet.release();
            address[] memory allowedTokenList = grantStorage.allowedTokenList;
            for (uint256 i; i < allowedTokenList.length;) {
                vestingWallet.release(allowedTokenList[i]);
                uint256 grantTokenAmount =
                    (vars.tokenAmount * IERC20(allowedTokenList[i]).balanceOf(daoFeePool)) / vars.tokenCirculation;
                if (grantTokenAmount > 0) {
                    emit D4AExchangeERC20ToERC20(
                        daoId, msg.sender, to, allowedTokenList[i], vars.tokenAmount, grantTokenAmount
                    );
                    D4AFeePool(payable(daoFeePool)).transfer(allowedTokenList[i], payable(to), grantTokenAmount);
                }
                unchecked {
                    ++i;
                }
            }
        }

        uint256 availableETH = daoFeePool.balance
            - (
                PriceStorage.layout().daoFloorPrices[daoId] == 0
                    ? 0
                    : rewardInfo.totalWeights[SettingsStorage.layout().drb.currentRound()]
            );
        uint256 ethAmount = (tokenAmount * availableETH) / vars.tokenCirculation;

        if (ethAmount != 0) D4AFeePool(payable(daoFeePool)).transfer(address(0x0), payable(to), ethAmount);

        emit D4AExchangeERC20ToETH(daoId, msg.sender, to, tokenAmount, ethAmount);

        return ethAmount;
    }

    function _checkCanvasExist(bytes32 canvasId) internal view {
        if (!CanvasStorage.layout().canvasInfos[canvasId].canvasExist) revert CanvasNotExist();
    }

    function _checkMintEligibility(
        bytes32 daoId,
        address account,
        bytes32[] memory proof,
        uint256 amount
    )
        internal
        view
    {
        if (SettingsStorage.layout().drb.currentRound() < DaoStorage.layout().daoInfos[daoId].startRound) {
            revert DaoNotStarted();
        }
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        if (
            DaoStorage.layout().daoInfos[daoId].dailyMint[l.drb.currentRound()] + amount
                > BasicDaoStorage.layout().basicDaoInfos[daoId].dailyMintCap
                && BasicDaoStorage.layout().basicDaoInfos[daoId].dailyMintCap != 0
        ) revert ExceedDailyMintCap();
        {
            if (!_ableToMint(daoId, account, proof, amount)) revert ExceedMinterMaxMintAmount();
        }
    }

    function _ableToMint(
        bytes32 daoId,
        address account,
        bytes32[] memory proof,
        uint256 amount
    )
        internal
        view
        returns (bool)
    {
        /*
        Checking priority
        1. blacklist
        2. if whitelist on, designated user mint cap
        3. NFT holder pass mint cap
        4. dao mint cap
        */
        IPermissionControl permissionControl = SettingsStorage.layout().permissionControl;

        if (permissionControl.isMinterBlacklisted(daoId, account)) {
            revert Blacklisted();
        }
        DaoMintInfo storage daoMintInfo = DaoStorage.layout().daoInfos[daoId].daoMintInfo;
        uint32 daoMintCap = daoMintInfo.daoMintCap;
        UserMintInfo memory userMintInfo = daoMintInfo.userMintInfos[account];

        Whitelist memory whitelist = permissionControl.getWhitelist(daoId);
        bool isWhitelistOff = whitelist.minterMerkleRoot == bytes32(0) && whitelist.minterNFTHolderPasses.length == 0
            && DaoStorage.layout().daoInfos[daoId].nftMinterCapInfo.length == 0;

        uint256 expectedMinted = userMintInfo.minted + amount;

        if (isWhitelistOff) {
            return daoMintCap == 0 ? true : expectedMinted <= daoMintCap;
        }

        if (permissionControl.inMinterWhitelist(daoId, account, proof)) {
            //revert NotInWhitelist();
            if (userMintInfo.mintCap != 0) return expectedMinted <= userMintInfo.mintCap;
            return true;
        }
        return _ableToMintFor721(daoId, expectedMinted, account);
    }

    function _ableToMintFor721(bytes32 daoId, uint256 expectedMinted, address account) internal view returns (bool) {
        IPermissionControl permissionControl = SettingsStorage.layout().permissionControl;
        NftMinterCapInfo[] memory nftMinterCapInfo = DaoStorage.layout().daoInfos[daoId].nftMinterCapInfo;
        uint256 length = nftMinterCapInfo.length;
        uint256 minMintCap = 1_000_000;
        bool hasMinterCapNft = false;
        for (uint256 i; i < length;) {
            if (IERC721Upgradeable(nftMinterCapInfo[i].nftAddress).balanceOf(account) > 0) {
                hasMinterCapNft = true;
                if (nftMinterCapInfo[i].nftMintCap < minMintCap) {
                    minMintCap = nftMinterCapInfo[i].nftMintCap;
                }
            }
            unchecked {
                ++i;
            }
        }
        if (hasMinterCapNft) {
            return expectedMinted <= minMintCap;
        }
        Whitelist memory whitelist = permissionControl.getWhitelist(daoId);
        return permissionControl.inMinterNFTHolderPasses(whitelist, account);
    }

    function _verifySignature(
        bytes32 daoId,
        bytes32 canvasId,
        string calldata tokenUri,
        uint256 nftFlatPrice,
        bytes calldata signature
    )
        internal
        view
    {
        // check for special token URIs first
        if (_isSpecialTokenUri(daoId, tokenUri)) return;

        SettingsStorage.Layout storage l = SettingsStorage.layout();
        bytes32 digest =
            _hashTypedData(keccak256(abi.encode(_MINTNFT_TYPEHASH, canvasId, keccak256(bytes(tokenUri)), nftFlatPrice)));
        address signer = ECDSAUpgradeable.recover(digest, signature);
        if (
            !IAccessControlUpgradeable(address(this)).hasRole(SIGNER_ROLE, signer)
                && signer != l.ownerProxy.ownerOf(canvasId)
        ) revert InvalidSignature();
    }

    function _isSpecialTokenUri(bytes32 daoId, string memory tokenUri) internal view returns (bool) {
        string memory specialTokenUriPrefix = BasicDaoStorage.layout().specialTokenUriPrefix;
        string memory daoIndex = LibString.toString(DaoStorage.layout().daoInfos[daoId].daoIndex);
        if (!tokenUri.startsWith(specialTokenUriPrefix.concat(daoIndex).concat("-"))) return false;
        // strip prefix, daoIndex at the start and `.json` at the end
        string memory tokenIndexString =
            tokenUri.slice(bytes(specialTokenUriPrefix).length + bytes(daoIndex).length + 1, bytes(tokenUri).length - 5);
        // try parse tokenIndex from string to uint256;
        uint256 tokenIndex;
        for (uint256 i; i < bytes(tokenIndexString).length; ++i) {
            if (bytes(tokenIndexString)[i] < "0" || bytes(tokenIndexString)[i] > "9") return false;
            tokenIndex = tokenIndex * 10 + (uint8(bytes(tokenIndexString)[i]) - 48);
        }
        if (tokenIndex == 0 || tokenIndex > ID4AProtocolReadable(address(this)).getDaoReserveNftNumber(daoId)) {
            return false;
        }
        return true;
    }

    function _fetchRightTokenUri(bytes32 daoId, uint256 tokenId) internal view returns (string memory) {
        string memory daoIndex = LibString.toString(DaoStorage.layout().daoInfos[daoId].daoIndex);
        return BasicDaoStorage.layout().specialTokenUriPrefix.concat(daoIndex).concat("-").concat(
            LibString.toString(tokenId)
        ).concat(".json");
    }

    function _mintNft(
        bytes32 daoId,
        bytes32 canvasId,
        string memory tokenUri,
        uint256 flatPrice,
        address to
    )
        internal
        returns (uint256 tokenId)
    {
        // for special token uri, if two same speical token uris are passes in at the same time, should fetch right
        // token uri first, then check for uri non-existence
        {
            BasicDaoStorage.BasicDaoInfo storage basicDaoInfo = BasicDaoStorage.layout().basicDaoInfos[daoId];
            if (_isSpecialTokenUri(daoId, tokenUri)) {
                ++basicDaoInfo.tokenId;
                if (canvasId != basicDaoInfo.canvasIdOfSpecialNft) {
                    revert NotCanvasIdOfSpecialTokenUri();
                }
                if (flatPrice != PriceStorage.layout().daoFloorPrices[daoId] && basicDaoInfo.unifiedPriceModeOff) {
                    revert NotBasicDaoFloorPrice();
                }
                tokenUri = _fetchRightTokenUri(daoId, basicDaoInfo.tokenId);
                tokenId = basicDaoInfo.tokenId;
            }
        }

        SettingsStorage.Layout storage l = SettingsStorage.layout();
        {
            _checkPauseStatus();
            _checkPauseStatus(canvasId);
            _checkCanvasExist(canvasId);
            _checkUriNotExist(tokenUri);
        }

        _checkPauseStatus(daoId);

        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        if (daoInfo.nftTotalSupply >= daoInfo.nftMaxSupply) revert NftExceedMaxAmount();

        ProtocolStorage.layout().uriExists[keccak256(abi.encodePacked(tokenUri))] = true;

        // get next mint price
        uint256 price;
        {
            uint256 currentRound = l.drb.currentRound();
            uint256 nftPriceFactor = daoInfo.nftPriceFactor;
            price = _getCanvasNextPrice(daoId, canvasId, flatPrice, daoInfo.startRound, currentRound, nftPriceFactor);
            _updatePrice(currentRound, daoId, canvasId, price, flatPrice, nftPriceFactor);
        }

        // split fee
        uint256 daoFee;
        bytes32 tempDaoId = daoId;
        bytes32 tempCanvasId = canvasId;
        CanvasStorage.CanvasInfo storage canvasInfo = CanvasStorage.layout().canvasInfos[canvasId];
        uint256 canvasRebateRatioInBps;
        {
            address protocolFeePool = l.protocolFeePool;
            address daoFeePool = daoInfo.daoFeePool;
            address canvasOwner = l.ownerProxy.ownerOf(tempCanvasId);
            uint256 daoShare = (
                flatPrice == 0 // Todo:
                    ? ID4AProtocolReadable(address(this)).getDaoFeePoolETHRatio(tempDaoId)
                    : ID4AProtocolReadable(address(this)).getDaoFeePoolETHRatioFlatPrice(tempDaoId)
            ) * price;

            if (
                (price - daoShare / BASIS_POINT - (price * l.protocolMintFeeRatioInBps) / BASIS_POINT) != 0
                    && ID4AProtocolReadable(address(this)).getNftMinterERC20Ratio(tempDaoId) != 0
            ) canvasRebateRatioInBps = canvasInfo.canvasRebateRatioInBps;
            daoFee = _splitFee(protocolFeePool, daoFeePool, canvasOwner, price, daoShare, canvasRebateRatioInBps);
        }

        _updateReward(
            daoId,
            canvasId,
            //如果mint的价格为0，为了达到以数量为权重分配reward的目的，统一传1 ether作为daoFeeAmount
            price == 0 ? 1 ether : daoFee,
            canvasRebateRatioInBps
        );

        // mint
        tokenId = D4AERC721(daoInfo.nft).mintItem(to, tokenUri, tokenId);
        {
            daoInfo.nftTotalSupply++;
            canvasInfo.tokenIds.push(tokenId);
            ProtocolStorage.layout().nftHashToCanvasId[keccak256(abi.encodePacked(tempDaoId, tokenId))] = canvasId;
        }

        emit D4AMintNFT(daoId, canvasId, tokenId, tokenUri, price);
    }

    function _updatePrice(
        uint256 currentRound,
        bytes32 daoId,
        bytes32 canvasId,
        uint256 price,
        uint256 flatPrice,
        uint256 nftPriceMultiplyFactor
    )
        internal
    {
        if (flatPrice == 0) {
            (bool succ,) = SettingsStorage.layout().priceTemplates[uint8(
                DaoStorage.layout().daoInfos[daoId].priceTemplateType
            )].delegatecall(
                abi.encodeWithSelector(
                    IPriceTemplate.updateCanvasPrice.selector,
                    daoId,
                    canvasId,
                    currentRound,
                    price,
                    nftPriceMultiplyFactor
                )
            );
            require(succ);
        }
    }

    struct BatchMintLocalVars {
        uint256 length;
        uint256 currentRound;
        uint256 nftPriceFactor;
        uint256 daoTotalShare;
        uint256 totalPrice;
    }

    function _getCanvasNextPrice(
        bytes32 daoId,
        bytes32 canvasId,
        uint256 flatPrice,
        uint256 startRound,
        uint256 currentRound,
        uint256 priceFactor
    )
        internal
        view
        returns (uint256 price)
    {
        PriceStorage.Layout storage priceStorage = PriceStorage.layout();
        uint256 daoFloorPrice = priceStorage.daoFloorPrices[daoId];
        PriceStorage.MintInfo memory maxPrice = priceStorage.daoMaxPrices[daoId];
        PriceStorage.MintInfo memory mintInfo = priceStorage.canvasLastMintInfos[canvasId];
        //对于D4A的DAO,还是按原来逻辑
        if (
            flatPrice == 0
                && (
                    BasicDaoStorage.layout().basicDaoInfos[daoId].unifiedPriceModeOff
                        || DaoStorage.layout().daoInfos[daoId].daoTag == DaoTag.D4A_DAO
                )
        ) {
            price = IPriceTemplate(
                SettingsStorage.layout().priceTemplates[uint8(DaoStorage.layout().daoInfos[daoId].priceTemplateType)]
            ).getCanvasNextPrice(startRound, currentRound, priceFactor, daoFloorPrice, maxPrice, mintInfo);
        } else {
            price = flatPrice;
        }
    }

    function _updateReward(
        bytes32 daoId,
        bytes32 canvasId,
        uint256 daoFeeAmount,
        uint256 canvasRebateRatioInBps
    )
        internal
    {
        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        (bool succ,) = SettingsStorage.layout().rewardTemplates[uint8(
            DaoStorage.layout().daoInfos[daoId].rewardTemplateType
        )].delegatecall(
            abi.encodeWithSelector(
                IRewardTemplate.updateReward.selector,
                UpdateRewardParam(
                    daoId,
                    canvasId,
                    daoInfo.token,
                    daoInfo.startRound,
                    l.drb.currentRound(),
                    daoInfo.mintableRound,
                    daoFeeAmount,
                    l.protocolERC20RatioInBps,
                    ID4AProtocolReadable(address(this)).getDaoCreatorERC20Ratio(daoId),
                    ID4AProtocolReadable(address(this)).getCanvasCreatorERC20Ratio(daoId),
                    ID4AProtocolReadable(address(this)).getNftMinterERC20Ratio(daoId),
                    canvasRebateRatioInBps
                )
            )
        );
        if (!succ) {
            /// @solidity memory-safe-assembly
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function _splitFee(
        address protocolFeePool,
        address daoFeePool,
        address canvasOwner,
        uint256 price,
        uint256 daoShare,
        uint256 canvasRebateRatioInBps
    )
        internal
        returns (uint256 daoFee)
    {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        daoFee = daoShare / BASIS_POINT;
        uint256 protocolFee = (price * l.protocolMintFeeRatioInBps) / BASIS_POINT;
        uint256 canvasFee = price - daoFee - protocolFee;
        uint256 rebateAmount = (canvasFee * canvasRebateRatioInBps) / BASIS_POINT;
        canvasFee -= rebateAmount;
        if (msg.value < price - rebateAmount) revert NotEnoughEther();
        uint256 dust = msg.value + rebateAmount - price;

        if (protocolFee > 0) SafeTransferLib.safeTransferETH(protocolFeePool, protocolFee);
        if (daoFee > 0) SafeTransferLib.safeTransferETH(daoFeePool, daoFee);
        if (canvasFee > 0) SafeTransferLib.safeTransferETH(canvasOwner, canvasFee);
        if (dust > 0) SafeTransferLib.safeTransferETH(msg.sender, dust);
    }

    function _domainNameAndVersion() internal pure override returns (string memory name, string memory version) {
        name = "ProtoDaoProtocol";
        version = "1";
    }
}
