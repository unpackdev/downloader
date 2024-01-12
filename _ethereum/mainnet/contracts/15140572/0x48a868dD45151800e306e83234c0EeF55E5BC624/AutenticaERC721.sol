// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;

import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./AccessControl.sol";
import "./IERC2981.sol";

import "./IERC721Autentica.sol";

contract AutenticaERC721 is
    Context,
    ERC721URIStorage,
    ERC721Enumerable,
    IERC721Autentica,
    IERC2981,
    AccessControl
{
    /// Number of decimals used for fees.
    uint8 public constant DECIMALS = 2;

    /// Create a new role identifier for the operator role.
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /// Additional token details needed for trading.
    struct TokenDetails {
        /// Address of the wallet that created the token.
        address creator;
        /// Address of the wallet who paid for gas fees.
        address investor;
        /// The value ranges between 0 and 100 multiplied by (10 ** DECIMALS).
        uint256 royaltyFee;
        /// The value ranges between 0 and 100 multiplied by (10 ** DECIMALS).
        uint256 investorFee;
    }

    /**
     * @dev Emitted when the address of the  Autentica Marketplace smart contract has been updated.
     */
    event ChangedMarketplace(
        address indexed oldAddress,
        address indexed newAddress
    );

    // Address of the Autentica Marketplace smart contract.
    address private _marketplace;

    /**
     * @dev Mapping from token ID to the token details structure which
     * contains information like the creator and investor address, royalty fee
     * and the investor fee.
     *
     * NOTE: The Autentica Marketplace smart contract supports royalties, so in order for the
     * creator to be paid, we need to know who created the token and that information must
     * stay the same even if the person who owns the token changes.
     *
     * NOTE: Autentica lets other people to pay for the gas fees of the token minting so
     * in that case the minter is not the creator and owner of the token.
     */
    mapping(uint256 => TokenDetails) private _tokenDetails;

    /**
     * Initializes the smart contract.
     */
    constructor() ERC721("Autentica Market", "AUTMKT") {
        // Grant the admin role to the owner
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        // Grant the operator role to the owner
        _setupRole(OPERATOR_ROLE, _msgSender());
    }

    /**
     * Returns the address of the Autentica Marketplace smart contract.
     */
    function marketplace() external view returns (address) {
        return _marketplace;
    }

    /**
     * @dev Sets the Autentica Marketplace smart contract address.
     * Requirements:
     *
     * - The caller must be admin.
     */
    function setMarketplace(address marketplaceAddress)
        external
        returns (address)
    {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "AutenticaERC721: Only admins can change this"
        );

        // Keep a reference to the old address
        address oldMarketplace = _marketplace;

        // Change the marketplace address
        _marketplace = marketplaceAddress;

        // Emit the event
        emit ChangedMarketplace(oldMarketplace, _marketplace);

        return _marketplace;
    }

    /**
     * @dev Number of decimals used for fees.
     */
    function decimals() external pure returns (uint8) {
        return DECIMALS;
    }

    /**
     * @dev Returns the Royalty fee of the `tokenId` token.
     * @param tokenId NFT ID.
     *
     * Requirements:
     *
     * - Token must exist.
     */
    function getRoyaltyFee(uint256 tokenId) external view returns (uint256) {
        require(_exists(tokenId), "AutenticaERC721: Token doesn't exist");

        return _tokenDetails[tokenId].royaltyFee;
    }

    /**
     * @dev Returns the Investor fee of the `tokenId` token.
     * @param tokenId NFT ID.
     *
     * Requirements:
     *
     * - Token must exist.
     */
    function getInvestorFee(uint256 tokenId) external view returns (uint256) {
        require(_exists(tokenId), "AutenticaERC721: Token doesn't exist");

        return _tokenDetails[tokenId].investorFee;
    }

    /**
     * @dev Returns the creator of the `tokenId` token.
     * @param tokenId NFT ID.
     *
     * NOTE: The Autentica Marketplace smart contract supports royalties, so in order for the
     * creator to be paid, we need to know who created the token and that information must
     * stay the same even if the person who owns the token changes.
     *
     * Requirements:
     *
     * - Token must exist.
     */
    function getCreator(uint256 tokenId) external view returns (address) {
        require(_exists(tokenId), "AutenticaERC721: Token doesn't exist");

        return _tokenDetails[tokenId].creator;
    }

    /**
     * @dev Returns the investor of the `tokenId` token.
     * @param tokenId NFT ID.
     *
     * NOTE: Autentica lets other people to pay for the gas fees of the token minting so
     * in that case the minter is not the creator and owner of the token.
     *
     * Requirements:
     *
     * - Token must exist.
     */
    function getInvestor(uint256 tokenId) external view returns (address) {
        require(_exists(tokenId), "AutenticaERC721: Token doesn't exist");

        return _tokenDetails[tokenId].investor;
    }

    /**
     * @dev Returns the token details of the `tokenId` token.
     * @param tokenId NFT ID.
     *
     * Requirements:
     *
     * - Token must exist.
     */
    function getTokenDetails(uint256 tokenId)
        external
        view
        returns (TokenDetails memory)
    {
        require(_exists(tokenId), "AutenticaERC721: Token doesn't exist");

        return _tokenDetails[tokenId];
    }

    /**
     * @dev Creates a token for `_msgSender()`. The creator of the token and the owner of it will
     * be assigned to `_msgSender()`.
     *
     * @param tokenId Token ID.
     * @param uri Token URI.
     * @param royaltyFee Royalty fee.
     *
     * See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - The `royaltyFee` must be less than or equal to 100 * (10 ** DECIMALS), meaning 100%.
     */
    function mint(
        uint256 tokenId,
        string memory uri,
        uint256 royaltyFee
    ) external {
        // Validate the operation
        canPerformMint(tokenId, royaltyFee);

        // Creator and Owner of the token
        address sender = _msgSender();

        // Mint
        _safeMint(sender, tokenId);
        _setTokenURI(tokenId, uri);

        // Set the token details
        _tokenDetails[tokenId] = TokenDetails({
            creator: sender,
            investor: address(0x0), // There is no investor in this case
            royaltyFee: royaltyFee,
            investorFee: 0 // This fee is zero because there is not investor in this case
        });
    }

    /**
     * Creates a token on behalf of a creator and approves the Autentica Marketplace smart contract.
     * The creator of the token and the owner of it will be assigned to `creator`
     * while the investor will be set to `_msgSender()`.
     *
     * @param creator Token creator and owner.
     * @param tokenId Token ID.
     * @param uri Token URI.
     * @param royaltyFee Royalty fee.
     * @param investorFee Investor fee.
     * @param v ECDSA `v` parameter.
     * @param r ECDSA `r` parameter.
     * @param s ECDSA `s` parameter.
     *
     * See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - The `royaltyFee` must be less than or equal to 100 * (10 ** DECIMALS), meaning 100%.
     * - the `investorFee` must be less than or equal to 100 * (10 ** DECIMALS), meaning 100%.
     * - The investor can't be the creator.
     * - The ECDSA signature must be signed by someone with the admin or operator role.
     */
    function investorMintingAndApproveMarketplace(
        address creator,
        uint256 tokenId,
        string memory uri,
        uint256 royaltyFee,
        uint256 investorFee,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        // Validate the operation
        canPerformInvestorMinting(
            creator,
            tokenId,
            royaltyFee,
            investorFee,
            v,
            r,
            s
        );

        // Mint
        _safeMint(creator, tokenId);
        _setTokenURI(tokenId, uri);

        // Set the token details
        _tokenDetails[tokenId] = TokenDetails({
            creator: creator,
            investor: _msgSender(),
            royaltyFee: royaltyFee,
            investorFee: investorFee
        });

        // Approve the Autentica Marketplace smart contract for this specific token only.
        _approve(_marketplace, tokenId);
    }

    /**
     * @notice Validate the mint.
     *
     * @param tokenId Token ID.
     * @param royaltyFee Royalty fee.
     */
    function canPerformMint(uint256 tokenId, uint256 royaltyFee)
        public
        view
        returns (bool)
    {
        // Make sure that the token doesn't exist
        require(!_exists(tokenId), "AutenticaERC721: Token already minted");

        // Make sure that the royalty fee is valid
        _validateFee(royaltyFee);

        return true;
    }

    /**
     * @notice Validate the investor minting.
     *
     * @param creator Token creator and owner.
     * @param tokenId Token ID.
     * @param royaltyFee Royalty fee.
     * @param investorFee Investor fee.
     * @param v ECDSA `v` parameter.
     * @param r ECDSA `r` parameter.
     * @param s ECDSA `s` parameter.
     */
    function canPerformInvestorMinting(
        address creator,
        uint256 tokenId,
        uint256 royaltyFee,
        uint256 investorFee,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns (bool) {
        // Make sure that the token doesn't exist
        require(!_exists(tokenId), "AutenticaERC721: Token already minted");

        // Make sure that the fees are valid
        _validateFee(royaltyFee);
        _validateFee(investorFee);

        // Make sure that the investor is not the creator
        require(
            _msgSender() != creator,
            "AutenticaERC721: Investor can't be the creator"
        );

        // Check signature
        require(
            _validateInvestorMintingSignature(
                creator,
                tokenId,
                royaltyFee,
                investorFee,
                v,
                r,
                s
            ),
            "AutenticaERC721: Invalid signature"
        );

        // Make sure that the marketplace address is set
        require(_marketplace != address(0x0), "AutenticaERC721: Marketplace address not set");

        return true;
    }

    /**
     * @dev Returns whether `tokenId` exists.
     */
    function exists(uint256 tokenId) external view returns (bool) {
        return super._exists(tokenId);
    }

    /**
     * Returns the Uniform Resource Identifier (URI) for a token.
     * @param tokenId Token ID for which to return the URI.
     *
     * Requirements:
     *
     * - Token must exist.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Called with the sale price to determine how much royalty is owed and to whom.
     * @param tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for `salePrice`
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        if (
            _exists(tokenId) == false ||
            _tokenDetails[tokenId].creator == address(0x0) ||
            _tokenDetails[tokenId].royaltyFee == 0
        ) {
            // Zero out everything
            return (address(0x0), 0);
        } else {
            // Return the address of the creator and the royalty proceeds
            return (
                _tokenDetails[tokenId].creator,
                (salePrice * _tokenDetails[tokenId].royaltyFee) /
                    (100 * 10**DECIMALS)
            );
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, AccessControl, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Autentica).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The creator, investor and royalty fee information is cleared when the token is burned.
     *
     * @param tokenId Token ID to burn.
     *
     * See {ERC721-_burn}.
     */
    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);

        // Cleanup the rest of the information
        delete _tokenDetails[tokenId];
    }

    /**
     * Hook that is called before any token transfer.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * Returns `true` if the signer has the admin or the operator role.
     *
     * @param creator - Artist.
     * @param tokenId - Token ID.
     * @param royaltyFee - Creator fee percentage.
     * @param investorFee - Investor fee percentage.
     * @param v ECDSA `v` parameter.
     * @param r ECDSA `r` parameter.
     * @param s ECDSA `s` parameter.
     */
    function _validateInvestorMintingSignature(
        address creator,
        uint256 tokenId,
        uint256 royaltyFee,
        uint256 investorFee,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private view returns (bool) {
        bytes32 hash = keccak256(
            abi.encode(address(this), creator, tokenId, royaltyFee, investorFee)
        );

        address signer = ecrecover(
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            ),
            v,
            r,
            s
        );

        return
            hasRole(DEFAULT_ADMIN_ROLE, signer) ||
            hasRole(OPERATOR_ROLE, signer);
    }

    /**
     * @dev Validates the fee value if it's within the allowed range.
     *
     * NOTE: The `value` must be less than or equal to 100 * (10 ** DECIMALS), meaning 100%.
     */
    function _validateFee(uint256 value) private pure {
        require(
            value <= 100 * (10**DECIMALS),
            "AutenticaERC721: Fee must be less than or equal to 100%"
        );
    }
}
