// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./IERC20.sol";
import "./AccessControl.sol";
import "./Context.sol";
import "./EIP712.sol";
import "./IChildToken.sol";
import "./IOnMint.sol";
import "./IOnBurn.sol";
import "./IOnTransfer.sol";

contract BoughtTheTopNFTChild is Context, AccessControl, ERC721Enumerable, EIP712, IChildToken {

    /// @notice Base of metdata URI
    string public baseTokenURI;

    /// @notice Ether fee to mint a new NFT
    uint256 public mintFee;

    /// @notice Contract to handle extra mint logic
    address public onMint;

    /// @notice Contract to handle extra burn logic
    address public onBurn;

    /// @notice Contract to handle extra transfer logic
    address public onTransfer;

    /// @notice NFTs that have been withdrawn to the root chain
    mapping (uint256 => bool) public withdrawnTokens;

    /// @notice Maxmimum number of NFTs that can be transferred in a batch due to gas limit restrictions
    uint256 public constant BATCH_LIMIT = 20;

    /// @notice EIP-712 typehash for mint
    bytes32 public constant MINT_TYPEHASH = keccak256("Mint(address to,uint256 tokenId,uint256 extra)");

    /// @notice Role identifer for minter
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @notice Role identifier for fee withdrawer
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");

    /// @notice Role identifier for cross-chain depositor
    bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");
    
    /// @notice Emitted when the base token URI changes
    event BaseTokenURIChanged(string uri);

    /// @notice Emitted when fees are withdrawn
    event FeesWithdrawn(uint256 amount);

    /// @notice Emitted when the {mintFee} changes
    event MintFeeChanged(uint256 fee);

    /// @notice Emitted when {onMint} changes
    event OnMintChanged(address set);

    /// @notice Emitted when {onBurn} changes
    event OnBurnChanged(address set);

    /// @notice Emitted when {onTransfer} changes
    event OnTransferChanged(address set);

    /// @notice Emitted when multiple NFTs are withdrawn
    event WithdrawnBatch(address indexed user, uint256[] tokenIds);

    /// @notice Emitted when an NFT is withdrawn
    event TransferWithMetadata(address indexed from, address indexed to, uint256 indexed tokenId, bytes metaData);

    /**
     * @dev Initialize contract, owner will be set to the
     * account that deploys the contract.
     */
    constructor() ERC721("BoughtThe.top NFT", "BTT") EIP712("BoughtThe.top NFT", "1") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        mintFee = 0.01 ether;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @dev Set the base URI for all tokens.
     *
     * See {ERC721-tokenURI}
     *
     * Requirements:
     *
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function setBaseTokenURI(string calldata uri) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "BoughtTheTopNFT: must have admin role");

        baseTokenURI = uri;
        emit BaseTokenURIChanged(uri);
    }

    /**
     * @dev Set the fee to mint a new token.
     *
     * Requirements:
     *
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function setMintFee(uint256 fee) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "BoughtTheTopNFT: must have admin role");

        mintFee = fee;
        emit MintFeeChanged(fee);
    }

    /**
     * @dev Set mint extra logic cotnract
     *
     * Requirements:
     *
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function setOnMint(address set) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "BoughtTheTopNFT: must have admin role");

        onMint = set;
        emit OnMintChanged(set);
    }

    /**
     * @dev Set burn extra logic cotnract
     *
     * Requirements:
     *
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function setOnBurn(address set) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "BoughtTheTopNFT: must have admin role");

        onBurn = set;
        emit OnBurnChanged(set);
    }

    /**
     * @dev Set transfer extra logic contract
     *
     * Requirements:
     *
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function setOnTransfer(address set) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "BoughtTheTopNFT: must have admin role");

        onTransfer = set;
        emit OnTransferChanged(set);
    }

    /**
     * @dev Withdraw all accumulated ether from the contract
     *
     * Requirements:
     *
     * - the caller must have the `WITHDRAW_ROLE`.
     */
    function withdrawFees() public {
        require(hasRole(WITHDRAW_ROLE, _msgSender()), "BoughtTheTopNFT: must have withdraw role");

        uint256 amount = address(this).balance;
        payable(_msgSender()).transfer(amount);
        emit FeesWithdrawn(amount);
    }

    function _mintBySignature(address to, uint256 tokenId, uint256 extra, uint8 v, bytes32 r, bytes32 s) internal {
        require(!withdrawnTokens[tokenId], "BoughtTheTopNFT: token exists on root chain");

        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
            MINT_TYPEHASH,
            to,
            tokenId,
            extra
        )));
        address signer = ECDSA.recover(digest, v, r, s);
        require(hasRole(MINTER_ROLE, signer), "BoughtTheTopNFT: must have minter role");

        // minters may mint for free
        if (!hasRole(MINTER_ROLE, _msgSender())) {
            require(msg.value == mintFee, "BoughtTheTopNFT: incorrect mint fee provided");
        }

        if (onMint != address(0))
            IOnMint(onMint).onMint(_msgSender(), to, tokenId, extra);

        _mint(to, tokenId);
    }

    /**
     * @dev Creates a new token for `to` with ID `tokenId` using an off-chain signature
     *
     * See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - {mintFee} wei sent with call if caller does not have `MINTER_ROLE`
     * - signature v, r, s must be signed by account with `MINTER_ROLE`
     */
    function mintTo(address to, uint256 tokenId, uint256 extra, uint8 v, bytes32 r, bytes32 s) public payable {
        _mintBySignature(to, tokenId, extra, v, r, s);
    }

    /**
     * @dev Creates a new token for caller with ID `tokenId` using an off-chain signature 
     *
     * See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - caller is owner of token
     * - {mintFee} wei sent with call if caller does not have `MINTER_ROLE`
     * - signature v, r, s must be signed by account with `MINTER_ROLE`
     */
    function mint(uint256 tokenId, uint256 extra, uint8 v, bytes32 r, bytes32 s) public payable {
        _mintBySignature(_msgSender(), tokenId, extra, v, r, s);
    }

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     * - {burnAllowed} must be true
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");

        if (onBurn != address(0))
            IOnBurn(onBurn).onBurn(tokenId);

        _burn(tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);

        if (onTransfer != address(0))
            IOnTransfer(onTransfer).onTransfer(from, to, tokenId);
    }

    /**
     * @dev Rescue any ERC-20 token the contract may hold
     *
     * @param _token ERC-20 token address
     *
     * Requirements:
     *
     * - the caller must have the `WITHDRAW_ROLE`.
     */
    function rescue(address _token) public {
        require(hasRole(WITHDRAW_ROLE, _msgSender()), "BoughtTheTopNFT: must have withdraw role");
        IERC20 token = IERC20(_token);
        token.transfer(_msgSender(), token.balanceOf(address(this)));
    }

    /**
     * @notice called when token is deposited on root chain
     * @dev Should be callable only by ChildChainManager
     * Should handle deposit by minting the required tokenId(s) for user
     * Should set `withdrawnTokens` mapping to `false` for the tokenId being deposited
     * Minting can also be done by other functions
     * @param user user address for whom deposit is being done
     * @param depositData abi encoded tokenIds. Batch deposit also supported.
     */
    function deposit(address user, bytes calldata depositData) external override {
        require(hasRole(DEPOSITOR_ROLE, _msgSender()), "BoughtTheTopNFT: must have depositor role");
        // deposit single
        if (depositData.length == 32) {
            uint256 tokenId = abi.decode(depositData, (uint256));
            withdrawnTokens[tokenId] = false;
            _mint(user, tokenId);

        // deposit batch
        } else {
            uint256[] memory tokenIds = abi.decode(depositData, (uint256[]));
            uint256 length = tokenIds.length;
            for (uint256 i; i < length; i++) {
                withdrawnTokens[tokenIds[i]] = false;
                _mint(user, tokenIds[i]);
            }
        }
    }

    /**
     * @notice called when user wants to withdraw token back to root chain
     * @dev Should handle withraw by burning user's token.
     * Should set `withdrawnTokens` mapping to `true` for the tokenId being withdrawn
     * This transaction will be verified when exiting on root chain
     * @param tokenId tokenId to withdraw
     */
    function withdraw(uint256 tokenId) external {
        require(_msgSender() == ownerOf(tokenId), "BoughtTheTopNFT: invalid token owner");
        withdrawnTokens[tokenId] = true;
        _burn(tokenId);
    }

    /**
     * @notice called when user wants to withdraw multiple tokens back to root chain
     * @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
     * @param tokenIds tokenId list to withdraw
     */
    function withdrawBatch(uint256[] calldata tokenIds) external {

        uint256 length = tokenIds.length;
        require(length <= BATCH_LIMIT, "BoughtTheTopNFT: exceeds batch limit");

        // Iteratively burn ERC721 tokens, for performing
        // batch withdraw
        for (uint256 i; i < length; i++) {

            uint256 tokenId = tokenIds[i];

            require(_msgSender() == ownerOf(tokenId), string(abi.encodePacked("BoughtTheTopNFT: invalid token owner ", tokenId)));
            withdrawnTokens[tokenId] = true;
            _burn(tokenId);
        }

        // At last emit this event, which will be used
        // in MintableERC721 predicate contract on L1
        // while verifying burn proof
        emit WithdrawnBatch(_msgSender(), tokenIds);
    }

    /**
     * @notice called when user wants to withdraw token back to root chain with token URI
     * @dev Should handle withraw by burning user's token.
     * Should set `withdrawnTokens` mapping to `true` for the tokenId being withdrawn
     * This transaction will be verified when exiting on root chain
     *
     * @param tokenId tokenId to withdraw
     */
    function withdrawWithMetadata(uint256 tokenId) external {

        require(_msgSender() == ownerOf(tokenId), "BoughtTheTopNFT: invalid token owner");
        withdrawnTokens[tokenId] = true;

        // Encoding metadata associated with tokenId & emitting event
        emit TransferWithMetadata(ownerOf(tokenId), address(0), tokenId, this.encodeTokenMetadata(tokenId));

        _burn(tokenId);
    }

    /**
     * @notice This method is supposed to be called by client when withdrawing token with metadata
     * and pass return value of this function as second paramter of `withdrawWithMetadata` method
     *
     * It can be overridden by clients to encode data in a different form, which needs to
     * be decoded back by them correctly during exiting
     *
     */
    function encodeTokenMetadata(uint256) external view virtual returns (bytes memory) {
        bytes memory empty;
        return empty;
    }
}
