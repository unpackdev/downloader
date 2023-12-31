// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./SignatureChecker.sol";

contract VSPPFP is ERC721Enumerable, ReentrancyGuard, Ownable, Pausable {
    using ECDSA for bytes32;

    // Mint cost for public mint
    uint256 public mintPrice;

    // Address of VSP contract
    address public VSP;

    // Address of VSP Black Card contract
    address public VSPBlackCard;

    // Base URI for the VSPPFP contract
    string public baseURI;

    // Signer address
    address public signer;

    // Signature Message
    string public constant signatureMessage =
        "I am proving ownership of wallet address ";

    // Mapping to check if a VSP token has been used to claim points
    mapping(uint256 => bool) public vspClaimed;

    // Mapping to check if a VSP BlackCard token has been used to claim points
    mapping(uint256 => bool) public vspBlackCardClaimed;

    // Mapping to check if a user has minted a PFP
    mapping(uint256 => bool) public userIdClaimed;

    // Struct to hold mint PFP payload
    struct mintPFPPayload {
        address walletAddress;
        uint256[] vsps;
        uint256[] blackCards;
        bytes signature;
    }

    // Event fired upon minting of a PFP
    event PFPMinted(
        uint256 indexed userId,
        mintPFPPayload[] payloads,
        uint256 indexed mintedToken,
        address indexed mintedTo
    );

    /**
     * @dev Contract constructor.
     * @param _signer The address of the signer used for signature verification.
     * @param _VSP The address of the VSP contract.
     * @param _VSPBlackCard The address of the VSPBlackCard contract.
     * @param _mintPrice The price for public minting.
     */
    constructor(
        address _signer,
        address _VSP,
        address _VSPBlackCard,
        uint256 _mintPrice,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        require(_VSP != address(0), "VSP cannot be the zero address");
        require(
            _VSPBlackCard != address(0),
            "VSPBlackCard cannot be the zero address"
        );
        require(_signer != address(0), "Signer cannot be the zero address");

        VSP = _VSP;
        VSPBlackCard = _VSPBlackCard;
        signer = _signer;
        mintPrice = _mintPrice;
        _pause();
    }

    /* ======= ONLY OWNER FUNCTIONS ======= */

    /**
     * @dev Sets the base URI for token metadata. Can only be called by the owner.
     * @param baseURI_ The new base URI.
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /**
     * @dev Sets the address of the VSP contract. Can only be called by the owner.
     * @param _VSP The address of the VSP contract.
     */
    function setVspContractAddress(address _VSP) external onlyOwner {
        require(_VSP != address(0), "VSP cannot be the zero address");

        VSP = _VSP;
    }

    /**
     * @dev Sets the address of the VSPBlackCard contract. Can only be called by the owner.
     * @param _VSPBlackCard The address of the VSPBlackCard contract.
     */
    function setVspBlackCardContractAddress(address _VSPBlackCard)
        external
        onlyOwner
    {
        require(
            _VSPBlackCard != address(0),
            "VSPBlackCard cannot be the zero address"
        );

        VSPBlackCard = _VSPBlackCard;
    }

    /**
     * @dev Sets the address of the signer used for signature verification. Can only be called by the owner.
     * @param _signer The address of the signer.
     */
    function setSigner(address _signer) external onlyOwner {
        require(_signer != address(0), "Signer cannot be the zero address");

        signer = _signer;
    }

    /**
     * @dev Sets the price for public minting. Can only be called by the owner.
     * @param _price the mint price in wei.
     */
    function setMintPrice(uint256 _price) external onlyOwner {
        mintPrice = _price;
    }

    /**
     * @dev Pauses the minting of PFPs. Can only be called by the owner.
     */
    function pauseMint() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the minting of PFPs. Can only be called by the owner.
     */
    function unpauseMint() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Function to withdraw contract funds.
     * @param _address address to transfer funds to.
     * @param _amount amount to be transferred in wei.
     */
    function withdrawFunds(address _address, uint256 _amount)
        external
        onlyOwner
    {
        require(_address != address(0), "Cannot withdraw to zero address");
        require(_amount > 0, "Cannot withdraw zero amount");
        require(address(this).balance >= _amount, "Insufficient funds");

        (bool success, ) = _address.call{value: _amount}("");

        require(success, "ETH transfer failed");
    }

    /**
     * @dev Mints PFPs by admin for a user paying via credit card. Can only be called by the owner.
     * @param userId User ID associated with the minting.
     * @param payloads Array of mintPFPPayload containing user data and signature.
     */
    function adminMint(
        uint256 userId,
        address walletAddress,
        mintPFPPayload[] calldata payloads
    ) external whenNotPaused nonReentrant onlyOwner {
        require(!userIdClaimed[userId], "User has minted a PFP already");

        for (uint256 i = 0; i < payloads.length; i++) {
            verifyPayload(userId, payloads[i]);
        }

        userIdClaimed[userId] = true;

        _safeMint(walletAddress, totalSupply());

        emit PFPMinted(userId, payloads, totalSupply() - 1, walletAddress);
    }

    /* ======= PUBLIC FUNCTIONS ======= */

    /**
     * @dev Mints PFPs for the caller.
     * @param userId User ID associated with the minting.
     * @param payloads Array of mintPFPPayload containing user data and signature.
     * @param adminSignature Signature to verify admin approval.
     */
    function mintPFP(
        uint256 userId,
        mintPFPPayload[] calldata payloads,
        bytes calldata adminSignature
    ) external payable whenNotPaused nonReentrant {
        require(!userIdClaimed[userId], "User has minted a PFP already");
        require(
            verifyAdminSignature(userId, adminSignature),
            "Invalid admin signature"
        );
        require(msg.value == mintPrice, "Invalid price paid");

        for (uint256 i = 0; i < payloads.length; i++) {
            verifyPayload(userId, payloads[i]);
        }

        userIdClaimed[userId] = true;

        _safeMint(msg.sender, totalSupply());

        emit PFPMinted(userId, payloads, totalSupply() - 1, msg.sender);
    }

    function claimedStatusForTokens(
        address collection,
        uint256[] memory tokenIds
    ) external view returns (bool[] memory) {
        bool[] memory tokenClaimedStatus = new bool[](tokenIds.length);

        if (collection == VSP) {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                tokenClaimedStatus[i] = vspClaimed[tokenIds[i]];
            }
        } else if (collection == VSPBlackCard) {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                tokenClaimedStatus[i] = vspBlackCardClaimed[tokenIds[i]];
            }
        }

        return tokenClaimedStatus;
    }

    /* ======= INTERNAL FUNCTIONS ======= */

    /**
     * @dev Overrides the base URI function.
     * @return The base URI for token metadata.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Checks the owner of a token for any collection.
     * @param tokenId The ID of the token.
     * @return The address of the token owner.
     */
    function checkOwnerOf(address collection, uint256 tokenId)
        internal
        view
        returns (address)
    {
        return IERC721(collection).ownerOf(tokenId);
    }

    /**
     * @dev Verifies the admin's signature for a user.
     * @param userId User ID associated with the minting.
     * @param signature Admin's signature.
     * @return A boolean indicating the validity of the signature.
     */
    function verifyAdminSignature(uint256 userId, bytes calldata signature)
        internal
        view
        returns (bool)
    {
        require(signer != address(0), "Signer not set");

        bytes32 hash = keccak256(abi.encodePacked(userId, msg.sender));
        bytes32 signedHash = hash.toEthSignedMessageHash();

        return
            SignatureChecker.isValidSignatureNow(signer, signedHash, signature);
    }

    /**
     * @dev Verifies the ownership of a wallet address.
     * @param walletAddress The wallet address to verify.
     * @param signature Signature to verify ownership.
     * @return A boolean indicating the ownership verification.
     */
    function verifyWalletOwnership(
        uint256 userId,
        address walletAddress,
        bytes memory signature
    ) internal view returns (bool) {
        bytes32 messageHash = keccak256(
            abi.encodePacked(signatureMessage, walletAddress, userId)
        );
        bytes32 signedHash = messageHash.toEthSignedMessageHash();

        return
            SignatureChecker.isValidSignatureNow(
                walletAddress,
                signedHash,
                signature
            );
    }

    /**
     * @dev Verifies the payload containing user data and tokens.
     * @param payload The mintPFPPayload struct containing user tokens and signature.
     */
    function verifyPayload(uint256 userId, mintPFPPayload calldata payload)
        internal
    {
        require(
            verifyWalletOwnership(
                userId,
                payload.walletAddress,
                payload.signature
            ),
            "Invalid user wallet address signature"
        );

        for (uint256 i = 0; i < payload.vsps.length; i++) {
            uint256 tokenId = payload.vsps[i];
            require(
                !vspClaimed[tokenId],
                "VSP token ID has already been used to claim points"
            );
            require(
                checkOwnerOf(VSP, tokenId) == payload.walletAddress,
                "VSP token ID is not owned by wallet address"
            );

            vspClaimed[tokenId] = true;
        }

        for (uint256 i = 0; i < payload.blackCards.length; i++) {
            uint256 tokenId = payload.blackCards[i];
            require(
                !vspBlackCardClaimed[tokenId],
                "VSP BlackCard token ID has already been used to claim points"
            );
            require(
                checkOwnerOf(VSPBlackCard, tokenId) == payload.walletAddress,
                "VSP BlackCard token ID is not owned by wallet address"
            );

            vspBlackCardClaimed[tokenId] = true;
        }
    }

    /* ======= MISCELLANEOUS FUNCTIONS ======= */

    /**
     * @dev Overrides the supportsInterface function to include ERC721Enumerable.
     * @param interfaceId The interface ID to check.
     * @return A boolean indicating support for the interface.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Fallback function to receive ether.
     */
    receive() external payable {}
}
