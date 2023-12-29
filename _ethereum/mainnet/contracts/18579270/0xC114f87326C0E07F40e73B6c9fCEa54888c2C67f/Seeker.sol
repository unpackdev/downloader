// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./ERC2981.sol";
import "./DefaultOperatorFilterer.sol";
import "./ECDSA.sol";
import "./Address.sol";
import "./ERC721A.sol";
import "./IERC4906.sol";

// Errors
error InvalidSaleState();
error InvalidSignature();
error AllowlistExceeded();
error WalletLimitExceeded();
error InvalidNewSupply();
error SupplyExceeded();
error TokenIsLocked(uint256 tokenId);
error WithdrawFailed();
error InvalidTreasuryAddress();

contract Seeker is
    DefaultOperatorFilterer,
    Ownable,
    ERC2981,
    ERC721A,
    IERC4906
{
    using Address for address payable;

    using ECDSA for bytes32;

    enum SaleStates {
        CLOSED,
        PRIVATE,
        WHITELIST,
        PUBLIC
    }

    // Number of NFTs users can mint in the public sale
    uint256 public constant PUBLIC_MINTS_PER_WALLET = 1;

    // The lockup period for NFTs minted through the Private
    uint256 public privateLockupPeriod = 3 weeks;

    // The lockup period for NFTs minted through the Whitelist
    uint256 public whitelistLockupPeriod = 0;

    // Total supply of the collection
    uint256 public maxSupply = 9630;

    // Address that signs messages used for minting
    address public mintSigner;

    // Current sale state
    SaleStates public saleState;

    // Mapping of token ids to lockup expirations
    mapping(uint256 => uint256) public tokenLockups;

    // Base metadata uri
    string private _baseTokenURI;

    //Treasury address
    address payable public treasuryAddress;

    event TreasuryUpdate(
        address indexed oldAddress,
        address indexed newAddress
    );

    constructor(
        string memory _name,
        string memory _symbol,
        address _signer,
        address _royaltyReceiver,
        address payable _treasuryAddress
    ) ERC721A(_name, _symbol) {
        // Set mint signer
        mintSigner = _signer;

        // 5% royalties by default
        _setDefaultRoyalty(_royaltyReceiver, 500);

        //Set the treasury address
        require(address(_treasuryAddress) != address(0));
        treasuryAddress = _treasuryAddress;
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
            ERC2981.supportsInterface(interfaceId) ||
            interfaceId == bytes4(0x49064906) ||
            super.supportsInterface(interfaceId);
    }

    // =========================================================================
    //                                 Metadata
    // =========================================================================

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
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
                ? string(abi.encodePacked(baseURI, _toString(tokenId)))
                : "";
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
    ) public override(ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * Overridden approve with operator filtering.
     */
    function approve(
        address operator,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperatorApproval(operator) {
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
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        // Validate that the token is not locked up
        if (tokenLockups[tokenId] >= block.timestamp) {
            revert TokenIsLocked(tokenId);
        }
        super.transferFrom(from, to, tokenId);
    }

    // =========================================================================
    //                              Minting Logic
    // =========================================================================

    /**
     * Private mint function. There is a lockup period for tokens minted through this method.
     * @param to Address that will receive the NFTs
     * @param qty Number of NFTs to mint
     * @param mintLimit Max number of NFTs the user can mint
     * @param signature Signature generated from the backend
     */
    function privateMint(
        address to,
        uint8 qty,
        uint8 mintLimit,
        bytes calldata signature
    ) external {
        if (saleState != SaleStates.PRIVATE) revert InvalidSaleState();
        if (_totalMinted() + qty > maxSupply) revert SupplyExceeded();

        // Validate signature
        bytes32 hashVal = keccak256(
            abi.encodePacked(msg.sender, mintLimit, saleState)
        );
        bytes32 signedHash = hashVal.toEthSignedMessageHash();
        if (signedHash.recover(signature) != mintSigner)
            revert InvalidSignature();

        // Validate that user still has allowlist spots
        uint64 alMintCount = _getAux(msg.sender) + qty;
        if (alMintCount > mintLimit) revert AllowlistExceeded();

        // Update allowlist used count
        _setAux(msg.sender, alMintCount);

        // Set lockup period for all token ids minted
        uint256 tokenId = _nextTokenId();
        unchecked {
            uint256 lockExpiration = block.timestamp + privateLockupPeriod;
            for (uint256 i; i < qty; ++i) {
                tokenLockups[tokenId + i] = lockExpiration;
            }
        }

        // Mint tokens
        _mint(to, qty);
    }

    /**
     * Whitelist mint function. There is a lockup period for tokens minted through this method.
     * @param to Address that will receive the NFTs
     * @param qty Number of NFTs to mint
     * @param mintLimit Max number of NFTs the user can mint
     * @param signature Signature generated from the backend
     */
    function whitelistMint(
        address to,
        uint8 qty,
        uint8 mintLimit,
        bytes calldata signature
    ) external {
        if (saleState != SaleStates.WHITELIST) revert InvalidSaleState();
        if (_totalMinted() + qty > maxSupply) revert SupplyExceeded();

        // Validate signature
        bytes32 hashVal = keccak256(
            abi.encodePacked(msg.sender, mintLimit, saleState)
        );
        bytes32 signedHash = hashVal.toEthSignedMessageHash();
        if (signedHash.recover(signature) != mintSigner)
            revert InvalidSignature();

        // Validate that user still has allowlist spots
        uint64 alMintCount = _getAux(msg.sender) + qty;
        if (alMintCount > mintLimit) revert AllowlistExceeded();

        // Update allowlist used count
        _setAux(msg.sender, alMintCount);

        // Set lockup period for all token ids minted
        uint256 tokenId = _nextTokenId();
        unchecked {
            uint256 lockExpiration = block.timestamp + whitelistLockupPeriod;
            for (uint256 i; i < qty; ++i) {
                tokenLockups[tokenId + i] = lockExpiration;
            }
        }

        // Mint tokens
        _mint(to, qty);
    }

    /**
     * Public mint function.
     * @param to Address that will receive the NFTs
     * @param qty Number of NFTs to mint
     */
    function publicMint(address to, uint256 qty) external {
        if (saleState != SaleStates.PUBLIC) revert InvalidSaleState();
        if (_totalMinted() + qty > maxSupply) revert SupplyExceeded();

        // Determine number of public mints by substracting AL mints from total mints
        if (
            _numberMinted(msg.sender) - _getAux(msg.sender) + qty >
            PUBLIC_MINTS_PER_WALLET
        ) {
            revert WalletLimitExceeded();
        }

        // Mint tokens
        _mint(to, qty);
    }

    /**
     * View function to get number of total mints a user has done.
     * @param user Address to check
     */
    function totalMintCount(address user) external view returns (uint256) {
        return _numberMinted(user);
    }

    // =========================================================================
    //                              Owner Only Methods
    // =========================================================================

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
     * Owner-only function to set the current sale state.
     * @param _saleState New sale state
     */
    function setSaleState(uint8 _saleState) external onlyOwner {
        saleState = SaleStates(_saleState);
    }

    /**
     * Owner-only function to set the whitelist lockup period
     * @param _whitelistLockupPeriod New whitelist lockup period
     */
    function setWhitelistLockupPeriod(
        uint256 _whitelistLockupPeriod
    ) external onlyOwner {
        whitelistLockupPeriod = _whitelistLockupPeriod;
    }

    /**
     * Owner-only function to set the private lockup period
     * @param _privateLockupPeriod New private lockup period
     */
    function setPrivateLockupPeriod(
        uint256 _privateLockupPeriod
    ) external onlyOwner {
        privateLockupPeriod = _privateLockupPeriod;
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
     * Owner-only function to withdraw funds in the contract to the treasury address.
     */
    function withdrawFundsToTreasury() external onlyOwner {
        (bool sent, ) = treasuryAddress.call{value: address(this).balance}("");
        if (!sent) {
            revert WithdrawFailed();
        }
    }

    /**
     * Owner-only function to set the base uri used for metadata.
     * @param baseURI uri to use for metadata
     */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
        emit BatchMetadataUpdate(0, maxSupply - 1);
    }

    /**
     * Owner-only function to adjust the lockup period for a given token.
     * @param tokenId Token Id to set the lockup period for
     * @param expiration The new lockup expiration
     */
    function setTokenLockup(
        uint256 tokenId,
        uint256 expiration
    ) external onlyOwner {
        tokenLockups[tokenId] = expiration;
    }

    /**
     * Owner-only function to set the treasury address. This value can only be modified by the owner.
     * @param _treasuryAddress The new treasure address
     */
    function setTreasuryAddress(
        address payable _treasuryAddress
    ) external onlyOwner {
        if (address(_treasuryAddress) == address(0)) {
            revert InvalidTreasuryAddress();
        }
        address payable oldAddress = treasuryAddress;
        treasuryAddress = _treasuryAddress;
        emit TreasuryUpdate(oldAddress, _treasuryAddress);
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
}
