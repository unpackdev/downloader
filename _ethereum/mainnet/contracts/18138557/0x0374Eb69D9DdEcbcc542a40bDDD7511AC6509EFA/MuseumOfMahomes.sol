// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./ERC721.sol";
import "./ERC2981.sol";
import "./LibString.sol";
import "./IDelegationRegistry.sol";

contract MuseumOfMahomes is ERC721, ERC2981 {
    using LibString for uint256;

    // Delegation auth
    IDelegationRegistry internal constant REGISTRY = IDelegationRegistry(0x00000000000076A84feF008CDAbe6409d2FE638B);

    // Pricing and minting
    uint256 internal constant MAX_SUPPLY = 3090; // Last tokenId will be 3089, because we start at 0
    uint256 internal constant BOXSET_SIZE = 6;
    uint256 public totalSupply = 0;
    uint256 public nextId = 0;
    uint256 public price = type(uint256).max; // Prevents minting until real price is set

    // Metadata management
    address public owner;
    address public metadataOwner;
    mapping(address => bool) public treasury;
    string public baseURI = "";
    bool public revealOpen = false;
    bool public redeemOpen = false;
    mapping(uint256 => bool) revealed;

    // Event emissions
    event MintBoxSet(uint256 indexed startTokenId, uint256 endTokenId);
    event Reveal(uint256 indexed tokenId);
    event Redeem(address indexed to, uint256 indexed tokenId);

    // Custom errors
    error AlreadyRevealed();
    error ExceedsMaxSupply();
    error FailedToSendEther();
    error NotRevealed();
    error MintZero();
    error Unauthorized();
    error WrongEthAmount();
    error WrongBoxSetMultiple();

    constructor() {
        owner = msg.sender;
        metadataOwner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    modifier onlyMetadataOwner() {
        if (msg.sender != metadataOwner) revert Unauthorized();
        _;
    }

    /* MINT, REVEAL, REDEEM */

    /// @notice Mint NFTs by ending ether or minting with a fiat payment solution
    /// @param to The address to receive the minted NFTs
    /// @param amount How many to mint
    /// @param mintBoxSet Set true if minting a multiple of 6 and want a box set
    /// @dev If amount is a multiple of `BOXSET_SIZE` and mintBoxSet=true, emit the MintBoxSet event for offchain metadata organizing
    function mint(address to, uint256 amount, bool mintBoxSet) external payable {
        if (msg.value != amount * price && !treasury[msg.sender]) revert WrongEthAmount();
        if (amount == 0) revert MintZero();
        if (nextId + amount > MAX_SUPPLY) revert ExceedsMaxSupply();
        if (mintBoxSet) {
            if (amount % BOXSET_SIZE != 0) revert WrongBoxSetMultiple();
            emit MintBoxSet(nextId, nextId + amount - 1);
        }
        unchecked {
            uint256 length = nextId + amount;
            for (uint256 tokenId = nextId; tokenId < length; ++tokenId) {
                _mint(to, tokenId);
            }
            nextId += amount;
            totalSupply += amount;
        }
    }

    /// @notice Mint and instantly burn to receive the physical
    /// @param to The address that will verify offchain where to send the physical
    /// @param amount How many to mint
    /// @param mintBoxSet Set true if minting a multiple of 6 and want a box set
    /// @dev If amount is a multiple of `BOXSET_SIZE` and mintBoxSet=true, emit the MintBoxSet event for offchain metadata organizing
    function mintPhysical(address to, uint256 amount, bool mintBoxSet) external payable {
        if (msg.value != amount * price && !treasury[msg.sender]) revert WrongEthAmount();
        if (amount == 0) revert MintZero();
        if (nextId + amount > MAX_SUPPLY) revert ExceedsMaxSupply();
        if (mintBoxSet) {
            if (amount % BOXSET_SIZE != 0) revert WrongBoxSetMultiple();
            emit MintBoxSet(nextId, nextId + amount - 1);
        }
        unchecked {
            uint256 length = nextId + amount;
            for (uint256 tokenId = nextId; tokenId < length; ++tokenId) {
                emit Redeem(to, tokenId);
            }
            nextId += amount;
            totalSupply += amount;
        }
    }

    /// @notice Reveal minted NFTs once ready
    /// @param tokenIds An array of tokenIds owned by or delegated to msg.sender
    /// @dev Pure event emission here, no token burning or minting, serves as onchain auth record of who has requested a reveal
    function reveal(uint256[] calldata tokenIds) external {
        if (!revealOpen) revert Unauthorized();
        unchecked {
            uint256 length = tokenIds.length;
            for (uint256 i = 0; i < length; ++i) {
                uint256 tokenId = tokenIds[i];
                _checkOwnerOrDelegate(msg.sender, _ownerOf(tokenId), tokenId);
                if (revealed[tokenId]) revert AlreadyRevealed();
                revealed[tokenId] = true;
                emit Reveal(tokenId);
            }
            totalSupply -= tokenIds.length;
        }
    }

    /// @notice Burn NFTs for physical redemption
    /// @param tokenIds An array of tokenIds owned by or delegated to msg.sender
    /// @dev Similar to reveal except it burns the tokenId here
    function burnAndRedeem(uint256[] calldata tokenIds) external {
        if (!redeemOpen) revert Unauthorized();
        unchecked {
            uint256 length = tokenIds.length;
            for (uint256 i = 0; i < length; ++i) {
                uint256 tokenId = tokenIds[i];
                _checkOwnerOrDelegate(msg.sender, _ownerOf(tokenId), tokenId);
                if (!revealed[tokenId]) revert NotRevealed();
                _burn(tokenId);
                emit Redeem(msg.sender, tokenId);
            }
            totalSupply -= tokenIds.length;
        }
    }

    /* DELEGATE SUPPORT */

    /// @dev Succeeds if holder and sender are the same, or if holder has delegated to sender, otherwise reverts
    function _checkOwnerOrDelegate(address sender, address holder, uint256 tokenId) internal view {
        if (holder != sender && !REGISTRY.checkDelegateForToken(sender, holder, address(this), tokenId)) {
            revert Unauthorized();
        }
    }

    /* CLAIM FUNDS */

    /// @notice Used by contract owner to claim mint funds
    function sweep(address _to) external onlyOwner {
        (bool sent,) = _to.call{value: address(this).balance}("");
        if (!sent) revert FailedToSendEther();
    }

    /* AUTH MANAGEMENT */

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    function setTreasury(address _treasury, bool enable) external onlyOwner {
        treasury[_treasury] = enable;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMetadataOwner(address _metadataOwner) external onlyMetadataOwner {
        metadataOwner = _metadataOwner;
    }

    function setBaseURI(string calldata _baseURI) external onlyMetadataOwner {
        baseURI = _baseURI;
    }

    function setRevealOpen(bool _revealOpen) external onlyMetadataOwner {
        revealOpen = _revealOpen;
    }

    function setRedeemOpen(bool _redeemOpen) external onlyMetadataOwner {
        redeemOpen = _redeemOpen;
    }

    /* ROYALTY DATA */

    function supportsInterface(bytes4 interfaceId) public pure override(ERC721, ERC2981) returns (bool) {
        return interfaceId == 0x2a55205a // ERC165 Interface ID for ERC2981
            || interfaceId == 0x01ffc9a7 // ERC165 Interface ID for ERC165
            || interfaceId == 0x80ac58cd // ERC165 Interface ID for ERC721
            || interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /// @dev See {ERC2981-_setDefaultRoyalty}.
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyMetadataOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /// @dev See {ERC2981-_deleteDefaultRoyalty}.
    function deleteDefaultRoyalty() external onlyMetadataOwner {
        _deleteDefaultRoyalty();
    }

    /// @dev See {ERC2981-_setTokenRoyalty}.
    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external onlyMetadataOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /// @dev See {ERC2981-_resetTokenRoyalty}.
    function resetTokenRoyalty(uint256 tokenId) external onlyMetadataOwner {
        _resetTokenRoyalty(tokenId);
    }

    /* METADATA VIEW */

    function tokenURI(uint256 id) public view override returns (string memory) {
        return LibString.concat(baseURI, id.toString());
    }

    function name() public pure override returns (string memory) {
        return "MuseumOfMahomesII";
    }

    function symbol() public pure override returns (string memory) {
        return "MoM";
    }
}
