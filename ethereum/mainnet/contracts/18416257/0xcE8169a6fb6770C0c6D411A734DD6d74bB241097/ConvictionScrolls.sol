// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./ERC721A.sol";
import "./ERC2981.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./OperatorFilterer.sol";

error InvalidSaleState();
error InsufficientPayment();
error SupplyExceeded();
error InvalidSignature();
error WalletLimitExceeded();
error InvalidNewSupply();
error WithdrawFailed();
error RevealNotOpen();
error ConvictionNFTNotSet();
error TransfersLocked();

// Interface for ConvictionNFT contract
interface IConvictionNFT {
    function mint(address to, uint256 tokenId) external;
}

contract ConvictionScrolls is ERC721A, ERC2981, Ownable, OperatorFilterer {
    using ECDSA for bytes32;

    enum SaleStates {
        CLOSED,
        ALLOWLIST,
        PUBLIC
    }

    // Number of NFT users can mint in allowlist sale
    uint256 public constant ALLOWLIST_MINTS_PER_WALLET = 3;

    // Number of NFTs users can mint in public sale
    uint256 public constant PUBLIC_MINTS_PER_WALLET = 3;

    // Price for the allowlist mint
    uint256 public allowlistPrice = 0.1 ether;

    // Price for the public mint
    uint256 public publicPrice = 0.2 ether;

    // Total supply of the collection
    uint256 public maxSupply = 10000;

    // Address that signs messages used for minting
    address public mintSigner;

    // Dictates whether transfers are enabled initially. Can be turned on later.
    bool public initialTransferLock = true;

    // Current sale state
    SaleStates public saleState;

    // Whether operator filtering is enabled
    bool public operatorFilteringEnabled;

    // Whether the reveal is open
    bool public revealOpen;

    // The PFP contract that each scroll will be redeemed for
    IConvictionNFT convictionNFT;

    // Base metadata uri
    string public baseTokenURI;

    constructor(
        string memory name,
        string memory symbol,
        address _signer,
        address _royaltyReceiver
    ) ERC721A(name, symbol) {
        // Set mint signer
        mintSigner = _signer;

        // Setup marketplace operator filtering
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        // 5% royalties
        _setDefaultRoyalty(_royaltyReceiver, 500);
    }

    /**
     * Allowlist mint function. Users are allowed to mint up to ALLOWLIST_MINTS_PER_WALLET nfts.
     * @param to Address that will receive the NFTs
     * @param qty Number of NFTs to mint
     * @param signature Signature generated from the backend
     */
    function allowlistMint(
        address to,
        uint8 qty,
        bytes calldata signature
    ) external payable {
        if (saleState != SaleStates.ALLOWLIST) revert InvalidSaleState();
        uint64 numAllowlistMints = _getAux(msg.sender) + qty;
        if (numAllowlistMints > ALLOWLIST_MINTS_PER_WALLET) {
            revert WalletLimitExceeded();
        }
        if (msg.value < qty * allowlistPrice) revert InsufficientPayment();
        if (_totalMinted() + qty > maxSupply) revert SupplyExceeded();

        // Validate signature
        bytes32 hashVal = keccak256(abi.encodePacked(msg.sender, saleState));
        bytes32 signedHash = hashVal.toEthSignedMessageHash();
        if (signedHash.recover(signature) != mintSigner) {
            revert InvalidSignature();
        }

        // Set allowlist amount
        _setAux(msg.sender, numAllowlistMints);

        // Mint tokens
        _mint(to, qty);
    }

    /**
     * Public mint function.
     * @param to Address that will receive the NFTs
     * @param qty Number of NFTs to mint
     */
    function publicMint(address to, uint8 qty) external payable {
        if (saleState != SaleStates.PUBLIC) revert InvalidSaleState();
        if (
            _numberMinted(msg.sender) - _getAux(msg.sender) + qty >
            PUBLIC_MINTS_PER_WALLET
        ) {
            revert WalletLimitExceeded();
        }
        if (msg.value < qty * publicPrice) revert InsufficientPayment();
        if (_totalMinted() + qty > maxSupply) revert SupplyExceeded();

        // Mint tokens
        _mint(to, qty);
    }

    /**
     * Owner-only mint function. Used to mint the team treasury.
     * @param to Address that will receive the NFTs
     * @param qty Number of NFTs to mint
     */
    function ownerMint(address to, uint256 qty) external onlyOwner {
        if (_totalMinted() + qty > maxSupply) revert SupplyExceeded();
        _mint(to, qty);
    }

    /**
     * Reveal function - burns a scroll and mints a corresponding Conviction NFT.
     * This function is enabled by the revealOpen flag. The ConvictionNFT contract must be set.
     * @param to Address to mint the Conviction NFT to
     * @param tokenIds A list of scroll token ids to burn
     */
    function reveal(address to, uint256[] calldata tokenIds) external {
        if (!revealOpen) revert RevealNotOpen();
        if (address(convictionNFT) == address(0)) revert ConvictionNFTNotSet();

        for (uint256 i; i < tokenIds.length; ) {
            uint256 tokenId = tokenIds[i];

            // Burn the scrolls and verify that the sender is the token owner
            _burn(tokenId, true);

            // Mint new token from the PFP contract with the same token id
            convictionNFT.mint(to, tokenId);

            unchecked {
                ++i;
            }
        }
    }

    // =========================================================================
    //                             Owner Settings
    // =========================================================================

    /**
     * Owner-only function to set the current sale state.
     * @param _saleState New sale state
     */
    function setSaleState(SaleStates _saleState) external onlyOwner {
        saleState = _saleState;
    }

    /**
     * Owner-only function to set the mint prices.
     * @param _allowlistPrice New paid allowlist mint price
     * @param _publicPrice New public mint price
     */
    function setPrices(
        uint256 _allowlistPrice,
        uint256 _publicPrice
    ) external onlyOwner {
        allowlistPrice = _allowlistPrice;
        publicPrice = _publicPrice;
    }

    /**
     * Owner-only function to set the mint signer.
     * @param _signer New mint signer
     */
    function setMintSigner(address _signer) external onlyOwner {
        mintSigner = _signer;
    }

    /**
     * Owner-only function to set the collection supply. This value can only be decreased.
     * @param _maxSupply The new supply count
     */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        if (_maxSupply >= maxSupply) revert InvalidNewSupply();
        maxSupply = _maxSupply;
    }

    /**
     * Owner-only function to withdraw funds in the contract to a destination address.
     * @param receiver Destination address to receive funds
     */
    function withdrawFunds(address receiver) external onlyOwner {
        (bool sent, ) = receiver.call{value: address(this).balance}("");
        if (!sent) {
            revert WithdrawFailed();
        }
    }

    /**
     * Owner only function to toggle the reveal status
     * @param open The new status
     */
    function setRevealOpen(bool open) external onlyOwner {
        revealOpen = open;
    }

    /**
     * Owner only function that sets the Conviction NFT contract
     * @param nft Address of the Conviction NFT contract
     */
    function setConvictionNFT(address nft) external onlyOwner {
        convictionNFT = IConvictionNFT(nft);
    }

    /**
     * Owner-only function to break the initial transfer lock
     */
    function breakTransferLock() external onlyOwner {
        initialTransferLock = false;
    }

    // =========================================================================
    //                           Operator filtering
    // =========================================================================

    /**
     * Overridden setApprovalForAll with operator filtering.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        if (initialTransferLock) revert TransfersLocked();
        super.setApprovalForAll(operator, approved);
    }

    /**
     * Overridden approve with operator filtering.
     */
    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        if (initialTransferLock) revert TransfersLocked();
        super.approve(operator, tokenId);
    }

    /**
     * Overridden transferFrom with operator filtering. For ERC721A, this will also add
     * operator filtering for both safeTransferFrom functions.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        if (initialTransferLock) revert TransfersLocked();
        super.transferFrom(from, to, tokenId);
    }

    /**
     * Owner-only function to toggle operator filtering.
     * @param value Whether operator filtering is on/off.
     */
    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    // =========================================================================
    //                                  ERC165
    // =========================================================================

    /**
     * Overridden supportsInterface with IERC721 support and ERC2981 support
     * @param interfaceId Interface Id to check
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    // =========================================================================
    //                                 ERC2891
    // =========================================================================

    /**
     * Owner-only function to set the royalty receiver and royalty rate
     * @param receiver Address that will receive royalties
     * @param feeNumerator Royalty amount in basis points. Denominated by 10000
     */
    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    // =========================================================================
    //                                 Metadata
    // =========================================================================

    /**
     * Owner-only function to set the base uri used for metadata.
     * @param baseURI uri to use for metadata
     */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * Function to retrieve the metadata uri for a given token. Reverts for tokens that don't exist.
     * @param tokenId Token Id to get metadata for
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json"))
                : "";
    }
}
