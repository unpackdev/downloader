// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IERC721.sol";
import "./LibGovNFTTierStorage.sol";
import "./LibAppStorage.sol";
import "./LibGovNFTTier.sol";
import "./LibMeta.sol";
import "./LibGovTier.sol";
import "./IGovTier.sol";

contract GovNFTTierFacet is Modifiers {
    /// @dev add NFT based Traditional or Single Token type tier levels
    /// @param _spTierLevel sp tier level struct
    function addSingleSpTierLevel(
        LibGovNFTTierStorage.SingleSPTierData memory _spTierLevel
    ) external onlyEditTierLevelRole(LibMeta._msgSender()) {
        require(_spTierLevel.ltv > 0, "Invalid LTV");
        LibGovNFTTierStorage.GovNFTTierStorage storage es = LibGovNFTTierStorage
            .govNftTierStorage();
        uint256 key = es.spTierLevelKeys.length + 1;
        require(
            key <= LibAppStorage.arrayMaxSize,
            "GTL: Max SP Tier Keys Exceeded"
        );
        es.spTierLevels[key] = _spTierLevel;
        es.spTierLevelKeys.push(key);
        emit LibGovNFTTierStorage.SingleSPTierLevelAdded(
            key,
            _spTierLevel.ltv,
            _spTierLevel.singleToken,
            _spTierLevel.multiToken,
            _spTierLevel.singleNft,
            _spTierLevel.multiNFT
        );
    }

    /// @dev function to assign tierlevel to the NFT contract only by super admin
    /// @param _nftContract nft token address whose tier is being added
    /// @param _tierLevel NFTTierdata for the nft contract
    function addNftTierLevel(
        address _nftContract,
        LibGovNFTTierStorage.NFTTierData memory _tierLevel
    ) external onlySuperAdmin(LibMeta._msgSender()) {
        LibGovNFTTierStorage.GovNFTTierStorage storage es = LibGovNFTTierStorage
            .govNftTierStorage();

        require(
            !LibGovNFTTier.isAlreadyNftTier(_nftContract),
            "Already Assigned Nft or Sp Tier"
        );
        require(
            _tierLevel.allowedNfts.length <= LibAppStorage.arrayMaxSize,
            "GTL: Max NFTs Exceeded"
        );
        require(
            _tierLevel.allowedSuns.length <= LibAppStorage.arrayMaxSize,
            "GTL: Max Sun Tokens Exceeded"
        );

        if (_tierLevel.isTraditional) {
            require(
                LibGovTier.isAlreadyTierLevel(_tierLevel.traditionalTier),
                "GTL:Traditional Tier Null"
            );
            require(_tierLevel.spTierId == 0, "GTL: Can't set spTierId");
        } else {
            require(
                es.spTierLevels[_tierLevel.spTierId].ltv > 0,
                "GTL: SP Tier Null"
            );
            require(
                _tierLevel.traditionalTier == 0,
                "GTL: Can't set traditionalTier"
            );
        }

        es.nftTierLevels[_nftContract] = _tierLevel;
        es.nftTierLevelsKeys.push(_nftContract);
        emit LibGovNFTTierStorage.NFTTierLevelAdded(
            _nftContract,
            _tierLevel.isTraditional,
            _tierLevel.spToken,
            _tierLevel.traditionalTier,
            _tierLevel.spTierId,
            _tierLevel.allowedNfts,
            _tierLevel.allowedSuns
        );
    }

    /// @dev this method adds the more nft tokens to already existing nft tier
    /// @param _nftContract nft token address
    /// @param _allowedNFTs allowed nfts addresses
    function addNFTTokensinNftTier(
        address _nftContract,
        address[] memory _allowedNFTs
    ) external onlySuperAdmin(LibMeta._msgSender()) {
        LibGovNFTTierStorage.GovNFTTierStorage storage es = LibGovNFTTierStorage
            .govNftTierStorage();
        LibGovNFTTierStorage.NFTTierData storage nftTier = es.nftTierLevels[
            _nftContract
        ];
        require(
            es.nftTierLevels[_nftContract].traditionalTier != 0 ||
                es.nftTierLevels[_nftContract].spTierId > 0,
            "Invalid index"
        );
        uint256 length = _allowedNFTs.length;
        require(
            nftTier.allowedNfts.length + length <= LibAppStorage.arrayMaxSize,
            "GTL: Max NFTs Exceeded"
        );

        isNFTsExist(_allowedNFTs, _nftContract);

        for (uint256 i = 0; i < length; i++) {
            nftTier.allowedNfts.push(_allowedNFTs[i]);
        }
        emit LibGovNFTTierStorage.AddNFTTokensinNftTier(
            _nftContract,
            _allowedNFTs
        );
    }

    /// @dev this methods adds the sun token token to the nft tier
    /// @param _nftContract nft contract address
    /// @param _allowedSunTokens adding more allowed sun token addresses
    function addNFTSunTokensinNftTier(
        address _nftContract,
        address[] memory _allowedSunTokens
    ) external onlySuperAdmin(LibMeta._msgSender()) {
        LibGovNFTTierStorage.GovNFTTierStorage storage es = LibGovNFTTierStorage
            .govNftTierStorage();
        LibGovNFTTierStorage.NFTTierData storage nftTier = es.nftTierLevels[
            _nftContract
        ];
        require(
            es.nftTierLevels[_nftContract].traditionalTier != 0 ||
                es.nftTierLevels[_nftContract].spTierId > 0,
            "Invalid index"
        );
        uint256 length = _allowedSunTokens.length;
        require(
            nftTier.allowedSuns.length + length <= LibAppStorage.arrayMaxSize,
            "GTL: Max Sun Tokens Exceeded"
        );

        isSunTokenExist(_allowedSunTokens, _nftContract);

        for (uint256 i = 0; i < length; i++) {
            nftTier.allowedSuns.push(_allowedSunTokens[i]);
        }
        emit LibGovNFTTierStorage.AddNFTSunTokensinNftTier(
            _nftContract,
            _allowedSunTokens
        );
    }

    /// @dev get all gov nft tier level length
    /// @return uint256 returns the length of the gov nft tier levels
    function getNFTTierLength() external view returns (uint256) {
        LibGovNFTTierStorage.GovNFTTierStorage storage es = LibGovNFTTierStorage
            .govNftTierStorage();
        return es.nftTierLevelsKeys.length;
    }

    function getAllNftTierKeys() external view returns (address[] memory) {
        LibGovNFTTierStorage.GovNFTTierStorage storage es = LibGovNFTTierStorage
            .govNftTierStorage();
        return es.nftTierLevelsKeys;
    }

    function getAllSpTierKeys() external view returns (uint256[] memory) {
        LibGovNFTTierStorage.GovNFTTierStorage storage es = LibGovNFTTierStorage
            .govNftTierStorage();
        return es.spTierLevelKeys;
    }

    /// @dev update single sp tier level
    function updateSingleSpTierLevel(
        uint256 _index,
        uint256 _ltv,
        bool _singleToken,
        bool _multiToken,
        bool _singleNft,
        bool multiNFT
    ) external onlyEditTierLevelRole(LibMeta._msgSender()) {
        require(_ltv > 0, "Invalid LTV");
        LibGovNFTTierStorage.GovNFTTierStorage storage es = LibGovNFTTierStorage
            .govNftTierStorage();
        require(es.spTierLevels[_index].ltv > 0, "Tier not exist");
        es.spTierLevels[_index].ltv = _ltv;
        es.spTierLevels[_index].singleToken = _singleToken;
        es.spTierLevels[_index].multiToken = _multiToken;
        es.spTierLevels[_index].singleNft = _singleNft;
        es.spTierLevels[_index].multiNFT = multiNFT;

        emit LibGovNFTTierStorage.SingleSPTierLevelUpdated(
            _index,
            _ltv,
            _singleToken,
            _multiToken,
            _singleNft,
            multiNFT
        );
    }

    /// @dev add NFT based Traditional or Single Token type tier levels
    /// @param index sp tier level index which is going to be remove
    function removeSingleSpTierLevel(
        uint256 index
    ) external onlyEditTierLevelRole(LibMeta._msgSender()) {
        require(index > 0, "Invalid index");
        LibGovNFTTierStorage.GovNFTTierStorage storage es = LibGovNFTTierStorage
            .govNftTierStorage();
        require(es.spTierLevels[index].ltv > 0, "Invalid index");
        delete es.spTierLevels[index];
        LibGovNFTTier._removeSingleSpTierLevelKey(
            LibGovNFTTier._getIndexSpTier(index)
        );
        emit LibGovNFTTierStorage.SingleSPTierLevelRemoved(index);
    }

    /// @dev add NFT based Traditional or Single Token type tier levels
    /// @param _contract contract address of the nft tier level
    function removeNftTierLevel(
        address _contract
    ) external onlyEditTierLevelRole(LibMeta._msgSender()) {
        require(_contract != address(0), "Invalid address");
        LibGovNFTTierStorage.GovNFTTierStorage storage es = LibGovNFTTierStorage
            .govNftTierStorage();
        require(
            es.nftTierLevels[_contract].traditionalTier != 0 ||
                es.nftTierLevels[_contract].spTierId > 0,
            "Invalid index"
        );
        delete es.nftTierLevels[_contract];
        LibGovNFTTier._removeNftTierLevelKey(
            LibGovNFTTier._getIndexNftTier(_contract)
        );
        emit LibGovNFTTierStorage.NftTierLevelRemoved(_contract);
    }

    /// @dev get the user nft tier
    /// @param _wallet address of the borrower
    /// @return nftTierData returns the nft tier data
    function getUserNftTier(
        address _wallet
    )
        external
        view
        returns (LibGovNFTTierStorage.NFTTierData memory nftTierData)
    {
        uint256 maxLTVFromNFTTier;
        address maxNFTTierAddress;
        LibGovNFTTierStorage.GovNFTTierStorage storage es = LibGovNFTTierStorage
            .govNftTierStorage();
        uint256 nftTiersLength = es.nftTierLevelsKeys.length;
        if (nftTiersLength == 0) {
            return es.nftTierLevels[address(0x0)];
        }

        for (uint256 i = 0; i < nftTiersLength; i++) {
            //user owns nft balannce
            uint256 currentLoanToValue;

            if (IERC721(es.nftTierLevelsKeys[i]).balanceOf(_wallet) > 0) {
                if (es.nftTierLevels[es.nftTierLevelsKeys[i]].isTraditional) {
                    currentLoanToValue = IGovTier(address(this))
                        .getSingleTierData(
                            es
                                .nftTierLevels[es.nftTierLevelsKeys[i]]
                                .traditionalTier
                        )
                        .loantoValue;
                } else {
                    currentLoanToValue = es
                        .spTierLevels[
                            es.nftTierLevels[es.nftTierLevelsKeys[i]].spTierId
                        ]
                        .ltv;
                }
                if (currentLoanToValue >= maxLTVFromNFTTier) {
                    maxNFTTierAddress = es.nftTierLevelsKeys[i];
                    maxLTVFromNFTTier = currentLoanToValue;
                }
            } else {
                continue;
            }
        }

        return es.nftTierLevels[maxNFTTierAddress];
    }

    /// @dev returns single sp tier data
    function getSingleSpTier(
        uint256 _spTierId
    ) external view returns (LibGovNFTTierStorage.SingleSPTierData memory) {
        LibGovNFTTierStorage.GovNFTTierStorage storage es = LibGovNFTTierStorage
            .govNftTierStorage();
        return es.spTierLevels[_spTierId];
    }

    /// @dev returns NFTTierLevel of an NFT contract
    /// @param _nftContract address of the nft contract
    function getNftTierLevel(
        address _nftContract
    ) external view returns (LibGovNFTTierStorage.NFTTierData memory) {
        LibGovNFTTierStorage.GovNFTTierStorage storage es = LibGovNFTTierStorage
            .govNftTierStorage();
        return es.nftTierLevels[_nftContract];
    }

    function isNFTsExist(
        address[] memory _nfts,
        address _nftContract
    ) internal {
        LibGovNFTTierStorage.GovNFTTierStorage storage es = LibGovNFTTierStorage
            .govNftTierStorage();

        for (uint256 i; i < _nfts.length; i++) {
            require(
                !es.isNFTExist[_nftContract][_nfts[i]],
                "nft already added"
            );
            es.isNFTExist[_nftContract][_nfts[i]] = true;
        }
    }

    function isSunTokenExist(
        address[] memory _sunTokens,
        address _nftContract
    ) internal {
        LibGovNFTTierStorage.GovNFTTierStorage storage es = LibGovNFTTierStorage
            .govNftTierStorage();
        for (uint256 i; i < _sunTokens.length; i++) {
            require(
                !es.isNFTExist[_nftContract][_sunTokens[i]],
                "sun token already added"
            );
            es.isNFTExist[_nftContract][_sunTokens[i]] = true;
        }
    }
}
