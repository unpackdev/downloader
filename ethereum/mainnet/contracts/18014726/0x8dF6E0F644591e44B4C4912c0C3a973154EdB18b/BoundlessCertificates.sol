// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Upgradeable.sol";
import "./Base64.sol";
import "./Strings.sol";
import "./IRoyaltiesRegistry.sol";
import "./BPS.sol";
import "./AccessControl.sol";

import "./console.sol";

interface IERC721LA {
    struct WhitelistConfig {
        bytes32 merkleRoot;
        uint8 amount;
        uint24 mintPriceInFinney;
        uint32 mintStartTS;
        uint32 mintEndTS;
    }

    struct Edition {
        uint24 maxSupply;
        uint24 currentSupply;
        uint24 burnedSupply;
        uint24 publicMintPriceInFinney;
        uint32 publicMintStartTS;
        uint32 publicMintEndTS;
        uint8 maxMintPerWallet;
        bool perTokenMetadata;
        uint24 burnableEditionId;
        uint24 amountToBurn;
    }

    struct EditionWithURI {
        Edition data;
        string baseURI;
    }

    function getEditionWithURI(
        uint256 _editionId
    ) external view returns (EditionWithURI memory);

    function EDITION_TOKEN_MULTIPLIER() external view returns (uint24);

    function getMintedCount(
        uint256 _editionId,
        address _recipient
    ) external view returns (uint256);

    function getWLConfig(
        uint256 editionId,
        uint8 amount,
        uint24 mintPriceInFinney
    ) external view returns (WhitelistConfig memory);

    function getEdition(
        uint256 _editionId
    ) external view returns (Edition memory);

    function whitelistMint(
        uint256 editionId,
        uint8 maxAmount,
        uint24 mintPriceInFinney,
        bytes32[] calldata merkleProof,
        uint24 quantity,
        address receiver,
        uint24 tokenId
    ) external payable;
}

interface IBoundlessContract {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract BoundlessCertificates is AccessControl, ERC721Upgradeable, IERC721LA {
    error NotTokenOwner();
    error IncorrectMintPrice();
    error MaxSupplyError();
    error FundTransferError();
    error InvalidEditionId();
    error InvalidMintData();
    error TokenNotFound();

    event CertificateMinted(
        uint256 indexed boundlessTokenId,
        uint256 indexed certificateTokenId,
        address indexed recipient
    );

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                             CONSTANTS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    address public constant BOUNDLESS_CONTRACT_ADDRESS =
        0xf9e39ce3463B8dEF5748Ff9B8F7825aF8F1b1617;

    IBoundlessContract private constant BOUNDLESS_CONTRACT =
        IBoundlessContract(0xf9e39ce3463B8dEF5748Ff9B8F7825aF8F1b1617);

    uint24 public constant EDITION_MAX_TOKENS = 10e5;
    uint256 public constant MINT_PRICE_IN_FINNEY = 800;
    uint256 public constant EDITION_ID = 1;

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                             STATE VARIABLES
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    Edition public edition;
    string public editionBaseURI;
    WhitelistConfig public whitelistConfig;
    IRoyaltiesRegistry public royaltyRegistry;

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                             INITIALIZER
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _collectionAdmin,
        address _royaltyRegistry
    ) external initializer {
        __ERC721_init(_name, _symbol);
        _grantRole(COLLECTION_ADMIN_ROLE, _collectionAdmin);
        royaltyRegistry = IRoyaltiesRegistry(_royaltyRegistry);
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                             SETTERS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function setEdition(
        string calldata _baseURI,
        uint24 _maxSupply,
        uint24 _publicMintPriceInFinney,
        uint32 _publicMintStartTS,
        uint32 _publicMintEndTS,
        uint8 _maxMintPerWallet,
        bool _perTokenMetadata,
        uint8 _burnableEditionId,
        uint8 _amountToBurn
    ) public onlyAdmin {
        if (_maxSupply >= EDITION_MAX_TOKENS - 1) {
            revert MaxSupplyError();
        }

        editionBaseURI = _baseURI;

        edition = Edition({
            maxSupply: _maxSupply,
            burnedSupply: 0,
            currentSupply: 0,
            publicMintPriceInFinney: _publicMintPriceInFinney,
            publicMintStartTS: _publicMintStartTS,
            publicMintEndTS: _publicMintEndTS,
            maxMintPerWallet: _maxMintPerWallet,
            perTokenMetadata: _perTokenMetadata,
            burnableEditionId: _burnableEditionId,
            amountToBurn: _amountToBurn
        });
    }

    function setWLConfig(
        uint256 _editionId,
        uint8 amount,
        uint24 mintPriceInFinney,
        uint32 mintStartTS,
        uint32 mintEndTS,
        bytes32 merkleRoot
    ) public onlyAdmin {
        WhitelistConfig memory config = WhitelistConfig({
            merkleRoot: merkleRoot,
            amount: amount,
            mintPriceInFinney: mintPriceInFinney,
            mintStartTS: mintStartTS,
            mintEndTS: mintEndTS
        });

        whitelistConfig = config;
    }

    function updateEditionBaseURI(string calldata _baseURI) public onlyAdmin {
        editionBaseURI = _baseURI;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                             GETTERS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    function getEdition(
        uint256 _editionId
    ) public view returns (Edition memory) {
        return edition;
    }

    function getEditionWithURI(
        uint256 _editionId
    ) public view returns (EditionWithURI memory) {
        return EditionWithURI({data: edition, baseURI: editionBaseURI});
    }

    function EDITION_TOKEN_MULTIPLIER() public pure returns (uint24) {
        return EDITION_MAX_TOKENS;
    }

    function getMintedCount(
        uint256 _editionId,
        address _recipient
    ) public view returns (uint256) {
        return balanceOf(_recipient);
    }

    function getWLConfig(
        uint256 editionId,
        uint8 amount,
        uint24 mintPriceInFinney
    ) public view returns (WhitelistConfig memory) {
        return whitelistConfig;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721Upgradeable) returns (string memory) {
        if (!_exists(tokenId)) {
            revert TokenNotFound();
        }

        if (edition.perTokenMetadata) {
            return
                string(
                    abi.encodePacked(editionBaseURI, Strings.toString(tokenId))
                );
        }

        return preRevealMetadata(tokenId);
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                      CERTIFICATE MINTING
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function whitelistMint(
        uint256 editionId,
        uint8 maxAmount,
        uint24 mintPriceInFinney,
        bytes32[] calldata merkleProof,
        uint24 quantity,
        address receiver,
        uint24 tokenId
    ) public payable {
        uint8 mintQuantity = 1;

        // check if edition supply is not maxed out
        if (edition.currentSupply == edition.maxSupply) {
            revert MaxSupplyError();
        }

        // Check if the sender is the owner of the boundless token
        uint256 boundlessTokenId = editionedTokenId(EDITION_ID, tokenId);
        if (
            IBoundlessContract(BOUNDLESS_CONTRACT).ownerOf(boundlessTokenId) !=
            msg.sender
        ) {
            revert NotTokenOwner();
        }

        // Finney to Wei
        uint256 mintPriceInWei = uint256(MINT_PRICE_IN_FINNEY) * 10e14;
        if (mintPriceInWei * mintQuantity > msg.value) {
            revert IncorrectMintPrice();
        }

        _safeMint(receiver, tokenId);

        edition.currentSupply += mintQuantity;

        emit CertificateMinted(
            tokenId, // boundless tokenID
            tokenId, // certificate tokenID
            receiver
        );

        // Send primary royalties
        (
            address payable[] memory wallets,
            uint256[] memory primarySalePercentages
        ) = royaltyRegistry.primaryRoyaltyInfo(address(this), boundlessTokenId);

        uint256 nReceivers = wallets.length;

        for (uint256 i = 0; i < nReceivers; i++) {
            uint256 royalties = BPS._calculatePercentage(
                msg.value,
                primarySalePercentages[i]
            );
            (bool sent, ) = wallets[i].call{value: royalties}("");

            if (!sent) {
                revert FundTransferError();
            }
        }
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                            ROYALTIES
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    /// @dev see: EIP-2981
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _value
    ) external view returns (address _receiver, uint256 _royaltyAmount) {
        return royaltyRegistry.royaltyInfo(address(this), _tokenId, _value);
    }

    function registerCollectionRoyaltyReceivers(
        RoyaltiesState.RoyaltyReceiver[] memory royaltyReceivers
    ) public onlyAdmin {
        royaltyRegistry.registerCollectionRoyaltyReceivers(
            address(this),
            msg.sender,
            royaltyReceivers
        );
    }

    function primaryRoyaltyInfo(
        uint256 tokenId
    ) public view returns (address payable[] memory, uint256[] memory) {
        return royaltyRegistry.primaryRoyaltyInfo(address(this), tokenId);
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                            ETHER FUNCTIONS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawAmount(
        address payable recipient,
        uint256 amount
    ) external onlyAdmin {
        (bool succeed, ) = recipient.call{value: amount}("");
        if (!succeed) {
            revert FundTransferError();
        }
    }

    function withdrawAll(address payable recipient) external onlyAdmin {
        (bool succeed, ) = recipient.call{value: balance()}("");
        if (!succeed) {
            revert FundTransferError();
        }
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                            INTERNAL FUNCTIONS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function editionedTokenId(
        uint256 editionId,
        uint256 tokenNumber
    ) internal pure returns (uint256 tokenId) {
        uint256 paddedEditionID = editionId * EDITION_MAX_TOKENS;
        tokenId = paddedEditionID + tokenNumber;
    }

    /**
     * @dev Given a tokenId return editionId and tokenNumber.
     * eg.: 3000005 => editionId 3 and tokenNumber 5
     */
    function parseEditionFromTokenId(
        uint256 tokenId
    ) public view returns (uint256 editionId, uint256 tokenNumber) {
        // Divide first to lose the decimal. ie. 1000001 / 1000000 = 1
        editionId = tokenId / EDITION_MAX_TOKENS;
        tokenNumber = tokenId - (editionId * EDITION_MAX_TOKENS);
    }

    function preRevealMetadata(
        uint256 tokenId
    ) internal pure returns (string memory) {
        string memory metadata = string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        "{",
                        '"name": "Certificate of Authenticity for Boundless NFT 1/1 Print",',
                        '"image": "https://v2-liveart.mypinata.cloud/ipfs/QmSkGCpgBWCqTt1JQnvqKqkTENmwW34DTR1J22RGJcrz8V",',
                        '"properties": { "artistName": "Yue Minjun" },',
                        '"description": "This certificate verifies the authenticity of your unique 1/1 print of your Boundless NFT by Yue Minjun. Shortly after purchase, it will be updated with the specific NFT and print details.",',
                        '"nft_contract_address": "0xf9e39ce3463B8dEF5748Ff9B8F7825aF8F1b1617",',
                        '"attributes": [',
                        '{ "trait_type": "Boundless number", "value": ',
                        Strings.toString(tokenId),
                        " },",
                        '{ "trait_type": "Certificate token Id", "value": ',
                        Strings.toString(tokenId),
                        " },",
                        '{ "trait_type": "Certificate claimed", "value": "false" }',
                        "]",
                        "}"
                    )
                )
            )
        );

        return metadata;
    }
}
