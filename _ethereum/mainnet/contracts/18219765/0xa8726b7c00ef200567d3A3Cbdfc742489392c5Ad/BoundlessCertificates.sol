// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Upgradeable.sol";
import "./Base64.sol";
import "./Strings.sol";
import "./IRoyaltiesRegistry.sol";
import "./BPS.sol";
import "./AccessControl.sol";
import "./WithOperatorRegistry.sol";
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

    struct EditionLA {
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
        bool stakingEnabled;
    }

    struct EditionWithURI {
        Edition data;
        string baseURI;
    }

    struct EditionWithURILA {
        EditionLA data;
        string baseURI;
    }

    function getEditionWithURI(
        uint256 _editionId
    ) external view returns (EditionWithURILA memory);

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

    function publicMint(
        uint32[] calldata discountedTokenIds,
        uint32[] calldata tokenIds,
        bool smallPrint,
        address receiver
    ) external payable;
}

interface IStakingContract {
    struct Staker {
        uint32 tokenId1;
        bool claimed1;
        uint32 tokenId2;
        bool claimed2;
        uint32 tokenId3;
        bool claimed3;
        uint32 tokenId4;
        bool claimed4;
        uint32 tokenId5;
        bool claimed5;
        uint8 stakedCount;
        uint32 stakedEndTime;
    }

    struct StakedNFT {
        uint32 idx;
        uint32 tokenId;
        bool claimed;
    }

    function getStakerDetails(
        address _staker
    ) external view returns (Staker memory stakerDetails);

    function claimDiscount(
        address _staker,
        uint256 _tokenId
    ) external;

    function stakingDetailsByLevel(
        uint8 numberOfNfts
    )
        external
        view
        returns (
            uint32 lockingPeriodSeconds,
            uint8 requiredNFTs,
            uint16 discountPercentage
        );

    function getDiscountedByWallet(
        address _staker
    ) external view returns (StakedNFT[] memory stakedNFTs, uint256 discount);
}

interface IBoundlessContract {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract BoundlessCertificates is
    AccessControl,
    ERC721Upgradeable,
    IERC721LA,
    WithOperatorRegistry
{
    error NotTokenOwner();
    error IncorrectMintPrice();
    error MaxSupplyError();
    error FundTransferError();
    error InvalidEditionId();
    error InvalidMintData();
    error TokenNotFound();
    error MintNotOpened();
    error AlreadyClaimed();

    event CertificateMinted(
        uint256 indexed boundlessTokenId,
        uint256 indexed certificateTokenId,
        address indexed recipient
    );

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                             CONSTANTS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    uint24 public constant EDITION_MAX_TOKENS = 10e5;
    // uint24 public constant EDITION_MAX_TOKENS = 10e5;
    uint256 public constant EDITION_ID = 1;

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                             STATE VARIABLES
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    Edition public edition;
    string public editionBaseURI;
    WhitelistConfig public whitelistConfig;
    IRoyaltiesRegistry public royaltyRegistry;
    address public stakingContract;
    address public boundlessContractAddress;
    IBoundlessContract public boundlessContract;
    mapping(uint256 => bool) public smallPrints;

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

    function setStakingContract(address _stakingContract) public onlyAdmin {
        stakingContract = _stakingContract;
    }

    function updateRoyaltyRegistryAddress(
        address _registryAddress
    ) public onlyAdmin {
        royaltyRegistry = IRoyaltiesRegistry(_registryAddress);
    }

    function setBoundlessContract(
        address _boundlessContractAddress
    ) public onlyAdmin {
        boundlessContractAddress = _boundlessContractAddress;
        boundlessContract = IBoundlessContract(_boundlessContractAddress);
    }

    modifier whenPublicMintOpened() {
        if (edition.publicMintEndTS < block.timestamp) {
            revert MintNotOpened();
        }
        _;
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
    ) public view returns (EditionWithURILA memory) {

        EditionLA memory editionLA = EditionLA({
            maxSupply: edition.maxSupply,
            burnedSupply:edition.burnedSupply,
            currentSupply: edition.currentSupply,
            publicMintPriceInFinney:edition.publicMintPriceInFinney,
            publicMintStartTS: edition.publicMintStartTS,
            publicMintEndTS: edition.publicMintEndTS,
            maxMintPerWallet: edition.maxMintPerWallet,
            perTokenMetadata: edition.perTokenMetadata,
            burnableEditionId: edition.burnableEditionId,
            amountToBurn: edition.amountToBurn,
            stakingEnabled:false 
        });
        return EditionWithURILA({data: editionLA, baseURI: editionBaseURI});
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

    function _getStakeNFTByTokenId(IStakingContract.StakedNFT[] memory stakedNFTs, uint256 tokenId) internal view returns (IStakingContract.StakedNFT memory stakedNFT) {
        for (uint256 index = 0; index < stakedNFTs.length; index++) {
            if (stakedNFTs[index].tokenId == tokenId) {
                return stakedNFTs[index];
            }
        }
        revert AlreadyClaimed();
    }

    function _validateOwnershipAndPrice(
        uint32[] calldata discountedTokenIds,
        uint32[] calldata tokenIds,
        bool smallPrint
    ) internal returns (uint256 totalCost) {
        uint256 baseMintPrice = uint256(edition.publicMintPriceInFinney) *
            10e14;

        if (smallPrint) {
            baseMintPrice = baseMintPrice / 2;
        }

        (IStakingContract.StakedNFT[] memory stakedNFTs, uint256 dicountBPS) = IStakingContract(
            stakingContract
        ).getDiscountedByWallet(msg.sender);

        for (uint256 index = 0; index < discountedTokenIds.length; index++) {
            // Validate ownership
            IStakingContract.StakedNFT memory stakedNFT = _getStakeNFTByTokenId(stakedNFTs, discountedTokenIds[index]);
            bool claimed = stakedNFT.claimed;

            // Check if token has already been claimed
            if (claimed) {
                revert InvalidMintData();
            }

            // Check token ownership
            uint256 boundlessTokenId = editionedTokenId(EDITION_ID, discountedTokenIds[index]);
            if (
                IBoundlessContract(boundlessContractAddress).ownerOf(
                    boundlessTokenId
                ) != msg.sender
            ) {
                revert NotTokenOwner();
            }

            IStakingContract(stakingContract).claimDiscount(msg.sender, discountedTokenIds[index]);
            
            // apply discount
            totalCost += baseMintPrice - BPS._calculatePercentage(baseMintPrice, dicountBPS);

        }

        for (uint256 index = 0; index < tokenIds.length; index++) {
            // Validate ownership
            uint32 tokenId = uint32(tokenIds[index]);

            // Check token ownership
            uint256 boundlessTokenId = editionedTokenId(EDITION_ID, tokenId);
            if (
                IBoundlessContract(boundlessContractAddress).ownerOf(
                    boundlessTokenId
                ) != msg.sender
            ) {
                revert NotTokenOwner();
            }

            // apply discount
            totalCost += baseMintPrice;
        }

        return totalCost;
    }

    function publicMint(
        uint32[] calldata discountedTokenIds,
        uint32[] calldata tokenIds,
        bool smallPrint,
        address receiver
    ) public payable whenPublicMintOpened {
        uint24 mintQuantity = uint24(discountedTokenIds.length + tokenIds.length);

        // check if edition supply is not maxed out
        if (edition.currentSupply + mintQuantity > edition.maxSupply) {
            revert MaxSupplyError();
        }

        uint256 totalPrice = _validateOwnershipAndPrice(
            discountedTokenIds,
            tokenIds,
            smallPrint
        );


        if (totalPrice > msg.value) {
            revert IncorrectMintPrice();
        }

        edition.currentSupply += mintQuantity;

        for (uint256 index = 0; index < discountedTokenIds.length; index++) {
            uint32 tokenId = uint32(discountedTokenIds[index]);
            _safeMint(receiver, tokenId);
            emit CertificateMinted(
                tokenId, // boundless tokenID
                tokenId, // certificate tokenID
                receiver
            );
            if (smallPrint) {
                smallPrints[tokenId] = true;
            }
        }

        for (uint256 index = 0; index < tokenIds.length; index++) {
            uint32 tokenId = uint32(tokenIds[index]);
            _safeMint(receiver, tokenId);
            emit CertificateMinted(
                tokenId, // boundless tokenID
                tokenId, // certificate tokenID
                receiver
            );
            if (smallPrint) {
                smallPrints[tokenId] = true;
            }
        }


        // Send primary royalties
        (
            address payable[] memory wallets,
            uint256[] memory primarySalePercentages
        ) = royaltyRegistry.primaryRoyaltyInfo(address(this), 1000960);

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
     *                      OPERATOR REGISTRY OVERRIDES
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    /// @dev See {IERC721-transferFrom}.

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721Upgradeable) onlyAllowedOperator(from) {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721Upgradeable) onlyAllowedOperator(from) {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721Upgradeable) onlyAllowedOperator(from) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721Upgradeable) onlyAllowedOperatorApproval(operator) {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(
        address to,
        uint256 tokenId
    ) public override(ERC721Upgradeable) onlyAllowedOperatorApproval(to) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
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

    function editionedTokenId(
        uint256 editionId,
        uint256 tokenNumber
    ) public pure returns (uint256 tokenId) {
        uint256 paddedEditionID = editionId * EDITION_MAX_TOKENS;
        tokenId = paddedEditionID + tokenNumber;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                            INTERNAL FUNCTIONS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

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
    ) internal view returns (string memory) {
        string memory metadata = string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '{ "name": "Certificate of Authenticity for Boundless NFT 1/1 Print",',
                        '"image": "https://v2-liveart.mypinata.cloud/ipfs/QmSkGCpgBWCqTt1JQnvqKqkTENmwW34DTR1J22RGJcrz8V",',
                        '"properties": { "artistName": "Yue Minjun" },',
                        '"description": "This certificate verifies the authenticity of your unique 1/1 print of your Boundless NFT by Yue Minjun. Shortly after purchase, it will be updated with the specific NFT and print details.",',
                        '"nft_contract_address": "0xf9e39ce3463B8dEF5748Ff9B8F7825aF8F1b1617",',
                        '"attributes": [{ "trait_type": "Boundless number", "value": ',
                        Strings.toString(tokenId),
                        '}, { "trait_type": "Certificate token Id", "value": ',
                        Strings.toString(tokenId),
                        ' },{ "trait_type": "Print size", "value": ',
                        smallPrints[tokenId] ? '"Small"' : '"Large"',
                        '}, { "trait_type": "Certificate claimed", "value": "false" }',
                        "]",
                        "}"
                    
                    )
                )
            )
        );

        return metadata;
    }
}
