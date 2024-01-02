// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
import "./BPS.sol";
import "./CustomErrors.sol";
import "./LANFTUtils.sol";
import "./ERC721State.sol";
import "./ERC721LACore.sol";
import "./IWhitelistable.sol";
import "./WhitelistableState.sol";
import "./AccessControl.sol";
import "./ILogicContract.sol";
import "./IERC4906.sol";

contract LogicContract is AccessControl, IERC4906, ILogicContract {
    address constant DEFAULT_WINTER_WALLET =
        0xdAb1a1854214684acE522439684a145E62505233;

    /**
     * @notice fetch edition struct data by editionId
     */
    function getEdition(
        uint256 _editionId
    ) public view returns (ERC721State.Edition memory) {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        if (_editionId > state._editionCounter) {
            revert CustomErrors.InvalidEditionId();
        }
        return state._editions[_editionId];
    }

    function editionedTokenId(
        uint256 editionId,
        uint256 tokenNumber
    ) public view returns (uint256 tokenId) {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        uint256 paddedEditionID = editionId * state._edition_max_tokens;
        tokenId = paddedEditionID + tokenNumber;
    }

    /**
     * @notice Creates a new Edition
     * Editions can be seen as collections within a collection.
     * The token Ids for the a given edition have the following format:
     * `[editionId][tokenNumber]`
     * eg.: The Id of the 2nd token of the 5th edition is: `5000002`
     *
     */
    function createEdition(
        string calldata _baseURI,
        uint24 _maxSupply,
        uint24 _publicMintPriceInFinney,
        uint32 _publicMintStartTS,
        uint32 _publicMintEndTS,
        uint8 _maxMintPerWallet,
        bool _perTokenMetadata,
        uint8 _burnableEditionId,
        uint8 _amountToBurn
    ) public onlyAdmin returns (uint256) {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        if (_maxSupply >= state._edition_max_tokens - 1) {
            revert CustomErrors.MaxSupplyError();
        }

        state._editions[state._editionCounter] = ERC721State.Edition({
            maxSupply: _maxSupply,
            burnedSupply: 0,
            currentSupply: 0,
            publicMintPriceInFinney: _publicMintPriceInFinney,
            publicMintStartTS: _publicMintStartTS,
            publicMintEndTS: _publicMintEndTS,
            maxMintPerWallet: _maxMintPerWallet,
            perTokenMetadata: _perTokenMetadata,
            burnableEditionId: _burnableEditionId,
            amountToBurn: _amountToBurn,
            stakingEnabled: false
        });

        state._baseURIByEdition[state._editionCounter] = _baseURI;

        state._printDataByEdition[state._editionCounter] = ERC721State
            .EditionWithPrintData({
                printVoucherContractAddress: address(0),
                publicMintPriceWithPrintInFinney: 0
            });

        emit EditionCreated(
            address(this),
            state._editionCounter,
            _maxSupply,
            _baseURI,
            _publicMintPriceInFinney,
            _perTokenMetadata
        );

        emit BatchMetadataUpdate(
            editionedTokenId(state._editionCounter, 1),
            editionedTokenId(state._editionCounter, _maxSupply)
        );

        state._editionCounter += 1;

        // -1 because we return the current edition Id
        return state._editionCounter - 1;
    }

    function updateEdition(
        uint256 editionId,
        uint24 _publicMintPriceInFinney,
        uint32 _publicMintStartTS,
        uint32 _publicMintEndTS,
        uint8 _maxMintPerWallet,
        uint24 _maxSupply,
        bool _perTokenMetadata
    ) external onlyAdmin {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        if (editionId > state._editionCounter) {
            revert CustomErrors.InvalidEditionId();
        }

        ERC721State.Edition storage edition = state._editions[editionId];
        if (_maxSupply < edition.currentSupply - edition.burnedSupply) {
            revert CustomErrors.MaxSupplyError();
        }
        edition.publicMintPriceInFinney = _publicMintPriceInFinney;
        edition.publicMintStartTS = _publicMintStartTS;
        edition.publicMintEndTS = _publicMintEndTS;
        edition.maxMintPerWallet = _maxMintPerWallet;
        edition.maxSupply = _maxSupply;
        edition.perTokenMetadata = _perTokenMetadata;
    }

    /**
     * @notice updates an edition base URI
     */
    function updateEditionBaseURI(
        uint256 editionId,
        string calldata _baseURI
    ) public onlyAdmin {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        if (editionId > state._editionCounter) {
            revert CustomErrors.InvalidEditionId();
        }

        ERC721State.Edition storage edition = state._editions[editionId];
        state._baseURIByEdition[editionId] = _baseURI;
        emit EditionUpdated(
            address(this),
            editionId,
            edition.maxSupply,
            _baseURI
        );
        emit BatchMetadataUpdate(
            editionedTokenId(editionId, 1),
            editionedTokenId(editionId, state._editions[editionId].maxSupply)
        );
    }

    function updateEditionPrintData(
        uint256 _editionId,
        address _newPrintVoucherAddress,
        uint24 _newPublicMintPriceWithPrintInFinney
    ) public onlyAdmin {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        if (_editionId > state._editionCounter) {
            revert CustomErrors.InvalidEditionId();
        }

        ERC721State.EditionWithPrintData memory editionPrintData = state
            ._printDataByEdition[_editionId];

        editionPrintData.printVoucherContractAddress = _newPrintVoucherAddress;

        editionPrintData
            .publicMintPriceWithPrintInFinney = _newPublicMintPriceWithPrintInFinney;

        state._printDataByEdition[_editionId] = editionPrintData;
    }
}
