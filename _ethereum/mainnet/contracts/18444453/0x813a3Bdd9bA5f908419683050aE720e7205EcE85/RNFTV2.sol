// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Import OpenZeppelin Contracts libraries
import "./OwnableUpgradeable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./ERC721RoyaltyUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./IRNFTV1.sol";

/// @title RNFT v2 contract
/// @author

contract RNFTV2 is
    ERC721RoyaltyUpgradeable,
    ERC721HolderUpgradeable,
    OwnableUpgradeable
{
    using StringsUpgradeable for uint256;

    mapping(uint256 => bytes32) public seed;
    mapping(uint256 => address) public originalOwner;
    mapping(address => uint256[]) public ownedTokens;
    mapping(address => mapping(uint256 => bool)) public hasOwnedToken;

    mapping(address => bool) public minters;

    string public baseURI;
    string public placeholderURI;
    bool public usePlaceholderURI;
    uint256 public totalSupply;
    uint256 public mintedNFT;
    uint256 public lastNFTTokenId;
    uint256 public maxSupply;
    IRNFTV1 public rnftV1;

    constructor() {}

    function initialize(
        address _rnftV1,
        uint256 _additionalSupply
    ) public initializer {
        require(address(_rnftV1) != address(0), "Zero Address");
        rnftV1 = IRNFTV1(_rnftV1);
        maxSupply = rnftV1.totalSupply() + _additionalSupply;
        mintedNFT = rnftV1.totalSupply();
        __ERC721_init("Genesis rootNFT", "RNFT");
        __Ownable_init();
    }

    /// @notice mint new NFTs
    /// @param to receiver address
    /// @param amount number of NFts to be minted
    function mint(address to, uint256 amount) external {
        require(minters[msg.sender], "not a minter");
        require(mintedNFT + amount <= maxSupply, "max supply reached");
        uint256 tokenId = mintedNFT;
        mintedNFT += amount;
        for (uint256 i = 0; i < amount; i++) {
            _mintV2(to, tokenId + i);
            originalOwner[tokenId + i] = to;
        }
    }

    /// @notice core mint function for v2
    /// @param to receiver address
    /// @param tokenId NFT token Id
    function _mintV2(address to, uint256 tokenId) internal {
        _mint(to, tokenId);
        // console.log("%s v2 token ID created", tokenId);
        seed[tokenId] = keccak256(
            abi.encodePacked(to, block.difficulty, tokenId)
        );
        totalSupply++;
    }

    function _mintV2WithV1Seed(address to, uint256 tokenId) internal {
        _mint(to, tokenId);
        seed[tokenId] = IRNFTV1(rnftV1).seed(tokenId);
        totalSupply++;
    }

    function _afterTokenTransfer(
        address,
        address to,
        uint256 firstTokenId,
        uint256
    ) internal virtual override {
        if (hasOwnedToken[to][firstTokenId] == false) {
            hasOwnedToken[to][firstTokenId] = true;
            ownedTokens[to].push(firstTokenId);
        }
    }

    /// @notice set base URI
    /// @param baseURI_ base URI
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /// @notice set royalty for NFT
    /// @param distAddress royalty destination address
    /// @param percentage percent
    function setRoyalty(
        address distAddress,
        uint96 percentage
    ) external onlyOwner {
        _setDefaultRoyalty(distAddress, percentage);
    }

    /// @notice set placeholder URI
    /// @param placeholderURI_ placeholder URI
    function setPlaceholderURI(
        string calldata placeholderURI_
    ) external onlyOwner {
        placeholderURI = placeholderURI_;
    }

    /// @notice set status of placeholder URI
    /// @param status set if active or deactive
    function setUsePlaceholderURI(bool status) external onlyOwner {
        usePlaceholderURI = status;
    }

    /// @notice tokenURI function
    /// @param tokenId token Id of NFT
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        if (usePlaceholderURI) {
            return placeholderURI;
        } else {
            return
                bytes(baseURI).length > 0
                    ? string(abi.encodePacked(baseURI, tokenId.toString()))
                    : "";
        }
    }

    /// @notice set minter for NFT mints
    /// @param minter new minter address
    /// @param status set if minter is active
    function setMinter(address minter, bool status) external onlyOwner {
        minters[minter] = status;
    }

    /// @notice retrieve user token array
    /// @param user address of user
    /// @return tokens retrieve tokens of user
    function getUserTokens(
        address user
    ) external view returns (uint256[] memory) {
        uint256[] memory tokens = new uint256[](balanceOf(user));
        uint256 j = 0;
        for (uint256 i = 0; i < ownedTokens[user].length; i++) {
            uint256 tokenId = ownedTokens[user][i];
            if (ownerOf(tokenId) == user) {
                tokens[j] = tokenId;
                j++;
            }
        }
        return tokens;
    }

    /// @notice migrate v1 tokens to v2
    /// @param tokenIds tokenId list of NFT
    function migrateBatch(uint256[] calldata tokenIds) external {
        require(tokenIds.length > 0, "ids should not empty");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _migrate(tokenIds[i]);
        }
    }

    /// @notice migrate v1 token to v2
    /// @param tokenId tokenId of NFT
    function _migrate(uint256 tokenId) internal {
        require(rnftV1.ownerOf(tokenId) == msg.sender, "not a holder");

        // lock V1 NFTs
        rnftV1.safeTransferFrom(msg.sender, address(0xdead), tokenId);
        // mint V2 NFTs
        _mintV2WithV1Seed(msg.sender, tokenId);
        // set the original owner of the token
        originalOwner[tokenId] = rnftV1.originalOwner(tokenId);
    }
}
