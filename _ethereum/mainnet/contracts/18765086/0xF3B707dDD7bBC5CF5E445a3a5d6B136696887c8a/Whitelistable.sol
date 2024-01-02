// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
import "./BPS.sol";
import "./CustomErrors.sol";
import "./LANFTUtils.sol";
import "./ERC721State.sol";
import "./ERC721LACore.sol";
import "./MerkleProof.sol";
import "./IWhitelistable.sol";
import "./WhitelistableState.sol";

interface ILiveArtXcard {
    function balanceOf(address owner) external view returns (uint256);
}

abstract contract Whitelistable is IWhitelistable, ERC721LACore {
    /**
     * Create a Whitelist configuration
     * @param _editionId the edition ID
     * @param amount How many mint allowed per Whitelist spot
     * @param mintPriceInFinney Price of the whitelist mint in Finney
     * @param mintStartTS Starting time of the Whitelist mint
     * @param mintEndTS Starting time of the Whitelist mint
     * @param merkleRoot The whitelist merkle root
     *
     */
    function setWLConfig(
        uint256 _editionId,
        uint8 amount,
        uint24 mintPriceInFinney,
        uint32 mintStartTS,
        uint32 mintEndTS,
        bytes32 merkleRoot,
        uint24 mintPriceWithPrintInFinney
    ) public onlyAdmin {
        WhitelistableState.WLState storage state = WhitelistableState
            ._getWhitelistableState();

        // This reverts if edition does not exist
        getEdition(_editionId);

        uint256 wlId = uint256(
            keccak256(
                abi.encodePacked(
                    _editionId,
                    amount,
                    mintPriceInFinney,
                    mintPriceWithPrintInFinney
                )
            )
        );

        if (state._whitelistConfig[wlId].amount != 0) {
            revert WhiteListAlreadyExists();
        }

        if (mintEndTS != 0 && mintEndTS < mintStartTS) {
            revert InvalidMintDuration();
        }

        WhitelistableState.WhitelistConfig
            memory whitelistConfig = WhitelistableState.WhitelistConfig({
                merkleRoot: merkleRoot,
                amount: amount,
                mintPriceInFinney: mintPriceInFinney,
                mintStartTS: mintStartTS,
                mintEndTS: mintEndTS,
                mintPriceWithPrintInFinney: mintPriceWithPrintInFinney
            });

        state._whitelistConfig[wlId] = whitelistConfig;
    }

    /**
     * Update a Whitelist configuration
     * @param _editionId Edition ID of the WL to be updated
     * @param _amount Amount of the WL to be updated
     * @param mintPriceInFinney Price of the WL to be updated
     * @param newAmount New Amount
     * @param newMintPriceInFinney New mint price in Finney
     * @param newMintStartTS New Mint time
     * @param newMerkleRoot New Merkle root
     *
     * Note: When changing a single property of the WL config,
     * make sure to also pass the value of the property that did not change.
     *
     */
    function updateWLConfig(
        uint256 _editionId,
        uint8 _amount,
        uint24 mintPriceInFinney,
        uint8 newAmount,
        uint24 newMintPriceInFinney,
        uint32 newMintStartTS,
        uint32 newMintEndTS,
        bytes32 newMerkleRoot,
        uint24 mintPriceWithPrintInFinney,
        uint24 newMintPriceWithPrintInFinney
    ) public onlyAdmin {
        WhitelistableState.WLState storage state = WhitelistableState
            ._getWhitelistableState();

        // This reverts if edition does not exist
        getEdition(_editionId);

        uint256 wlId = uint256(
            keccak256(
                abi.encodePacked(
                    _editionId,
                    _amount,
                    mintPriceInFinney,
                    mintPriceWithPrintInFinney
                )
            )
        );
        WhitelistableState.WhitelistConfig memory whitelistConfig;

        // If amount or price differ, then set previous WL config key to amount 0, which effectively disable the WL
        if (
            _amount != newAmount ||
            mintPriceInFinney != newMintPriceInFinney ||
            mintPriceWithPrintInFinney != newMintPriceWithPrintInFinney
        ) {
            state._whitelistConfig[wlId] = WhitelistableState.WhitelistConfig({
                merkleRoot: newMerkleRoot,
                amount: 0,
                mintPriceInFinney: newMintPriceInFinney,
                mintStartTS: newMintStartTS,
                mintEndTS: newMintEndTS,
                mintPriceWithPrintInFinney: newMintPriceWithPrintInFinney
            });
            wlId = uint256(
                keccak256(
                    abi.encodePacked(
                        _editionId,
                        newAmount,
                        newMintPriceInFinney,
                        newMintPriceWithPrintInFinney
                    )
                )
            );
            state._whitelistConfig[wlId] = whitelistConfig;
        }

        if (newMintEndTS != 0 && newMintEndTS < newMintStartTS) {
            revert InvalidMintDuration();
        }

        whitelistConfig = WhitelistableState.WhitelistConfig({
            merkleRoot: newMerkleRoot,
            amount: newAmount,
            mintPriceInFinney: newMintPriceInFinney,
            mintStartTS: newMintStartTS,
            mintEndTS: newMintEndTS,
            mintPriceWithPrintInFinney: newMintPriceWithPrintInFinney
        });

        state._whitelistConfig[wlId] = whitelistConfig;
    }

    /**
     * Whitelist mint function
     * @param _editionId the edition ID
     * @param _maxAmount How many mint allowed per Whitelist spot
     * @param _merkleProof the merkle proof of the minter
     * @param _quantity How many NFTs to mint
     * @param _recipient The recipient of the NFTs
     * @param _xCardTokenId The XCard token ID
     * @param _mintPriceWithPrintInFinney The mint price with print in Finney
     */
    function whitelistMint(
        uint256 _editionId,
        uint8 _maxAmount,
        uint24 _mintPriceInFinney,
        bytes32[] calldata _merkleProof,
        uint24 _quantity,
        address _recipient,
        uint24 _xCardTokenId,
        uint24 _mintPriceWithPrintInFinney
    ) public payable {
        _validateWhitelistMintingParameters(
            _editionId,
            _maxAmount,
            _mintPriceInFinney,
            _merkleProof,
            _quantity,
            _mintPriceWithPrintInFinney
        );

        _validateMintPrice(_mintPriceInFinney, _quantity);

        uint256 firstTokenId = _safeMint(_editionId, _quantity, _recipient);

        _sendRoyaltiesAfterMint(firstTokenId);
    }

    /**
     * Whitelist mint with print function
     * @param _editionId the edition ID
     * @param _maxAmount How many mint allowed per Whitelist spot
     * @param _merkleProof the merkle proof of the minter
     * @param _quantity How many NFTs to mint
     * @param _recipient The recipient of the NFTs
     * @param _xCardTokenId The XCard token ID
     * @param _mintPriceWithPrintInFinney The mint price with print in Finney
     */
    function whitelistMintWithPrint(
        uint256 _editionId,
        uint8 _maxAmount,
        uint24 _mintPriceInFinney,
        bytes32[] calldata _merkleProof,
        uint24 _quantity,
        address _recipient,
        uint24 _xCardTokenId,
        uint24 _mintPriceWithPrintInFinney
    ) public payable {
        ERC721State.EditionWithPrintData memory printData = getEditionPrintData(
            _editionId
        );

        _validateWhitelistMintingParameters(
            _editionId,
            _maxAmount,
            _mintPriceInFinney,
            _merkleProof,
            _quantity,
            _mintPriceWithPrintInFinney
        );

        _validateEditionPrintData(printData);

        _validateMintPrice(_mintPriceWithPrintInFinney, _quantity);

        uint256 firstTokenId = _safeMint(_editionId, _quantity, _recipient);

        _sendRoyaltiesAfterMint(firstTokenId);
        _mintPrintVouchers(_editionId, _quantity, firstTokenId);
    }

    /**
     * Get WL config for given editionId, amout, and mintPrice.
     * Should not be used internally when trying to modify the state as it returns a memory copy of the structs
     */
    function getWLConfig(
        uint256 editionId,
        uint8 amount,
        uint24 mintPriceInFinney,
        uint24 mintPriceWithPrintInFinney
    ) public view returns (WhitelistableState.WhitelistConfig memory) {
        WhitelistableState.WLState storage state = WhitelistableState
            ._getWhitelistableState();

        // This reverts if edition does not exist
        getEdition(editionId);

        uint256 wlId = uint256(
            keccak256(
                abi.encodePacked(
                    editionId,
                    amount,
                    mintPriceInFinney,
                    mintPriceWithPrintInFinney
                )
            )
        );
        WhitelistableState.WhitelistConfig storage whitelistConfig = state
            ._whitelistConfig[wlId];

        if (whitelistConfig.amount == 0) {
            revert CustomErrors.NotFound();
        }

        return whitelistConfig;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                         INTERNAL FUNCTIONS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function _validateWhitelistMintingParameters(
        uint256 _editionId,
        uint8 maxAmount,
        uint24 mintPriceInFinney,
        bytes32[] calldata merkleProof,
        uint24 _quantity,
        uint24 mintPriceWithPrintInFinney
    ) internal {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();

        // This reverts if WL does not exist (or is disabled)
        WhitelistableState.WhitelistConfig memory whitelistConfig = getWLConfig(
            _editionId,
            maxAmount,
            mintPriceInFinney,
            mintPriceWithPrintInFinney
        );

        // Check for allowed mint count
        uint256 mintCountKey = uint256(
            keccak256(abi.encodePacked(_editionId, msg.sender))
        );

        if (
            state._mintedPerWallet[mintCountKey] + _quantity >
            whitelistConfig.amount
        ) {
            revert CustomErrors.MaximumMintAmountReached();
        }

        if (
            whitelistConfig.mintStartTS == 0 ||
            block.timestamp < whitelistConfig.mintStartTS
        ) {
            revert CustomErrors.MintClosed();
        }

        if (
            whitelistConfig.mintEndTS != 0 &&
            block.timestamp > whitelistConfig.mintEndTS
        ) {
            revert CustomErrors.MintClosed();
        }

        // We use msg.sender for the WL merkle root
        // Ran only if the user is not an XCard holder
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        if (
            !MerkleProof.verify(
                merkleProof,
                whitelistConfig.merkleRoot,
                leaf
            ) &&
            ILiveArtXcard(state._xCardContractAddress).balanceOf(msg.sender) ==
            0
        ) {
            revert NotWhitelisted();
        }

        state._mintedPerWallet[mintCountKey] += _quantity;
    }
}
