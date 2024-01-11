// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract PixelPonyHornstars is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    // @dev Base uri for the nft
    string private baseURI;

    // @dev A flag for collecting reserves
    bool private isCollected = false;

    // @dev Pre-reveal base uri
    string public preRevealBaseURI;

    // @dev The total supply of the collection
    uint256 public maxSupply = 0;

    // @dev The max amount of mints per wallet
    uint256 public maxPerWallet = 2;

    // @dev The merkle root proof
    bytes32 public merkleRoot;

    // @dev An address mapping for founder claim
    mapping(address => bool) public addressToFounderClaim;

    // @dev An address mapping to add max mints per wallet
    mapping(address => uint256) public addressToMinted;

    // @dev A reveal flag
    bool public isRevealed = false;

    // @dev A flag for freezing metadata
    bool public isFrozen = false;

    // @dev A flag for pimp claim enabled
    bool public isPimpClaimEnabled = true;

    constructor() ERC721A("Pixel Pony Hornstars", "PPH") {}

    /**
     * @notice Pimp minter
     * @param _proof The bytes32 array proof to verify the merkle root
     */
    function pimpMint(bytes32[] calldata _proof) public nonReentrant {
        require(isPimpClaimEnabled, "123");
        require(!addressToFounderClaim[msg.sender], "69");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_proof, merkleRoot, leaf), "420");
        addressToFounderClaim[msg.sender] = true;
        _mint(msg.sender, 1);
    }

    /**
     * @notice Whitelisted minting function which requires a merkle proof
     * @param _proof The bytes32 array proof to verify the merkle root
     */
    function mint(bytes32[] calldata _proof) public nonReentrant {
        require(!isPimpClaimEnabled, "123");
        require(addressToMinted[msg.sender] + 1 < maxPerWallet, "1337");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_proof, merkleRoot, leaf), "420");
        addressToMinted[msg.sender] += 1;
        _mint(msg.sender, 1);
    }

    /**
     * @notice Public minting function
     */
    function publicMint() public nonReentrant {
        require(totalSupply() + 1 < maxSupply, "96");
        require(addressToMinted[msg.sender] + 1 < maxPerWallet, "1337");
        addressToMinted[msg.sender] += 1;
        _mint(msg.sender, 1);
    }

    /**
     * @notice Burn an nft by tokenId, runs approval
     */
    function burn(uint256 tokenId) public {
        _burn(tokenId, true);
    }

    /**
     * @dev Returns the starting token ID.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Returns the URI for a given token id
     * @param _tokenId A tokenId
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(_tokenId)) revert OwnerQueryForNonexistentToken();
        if (!isRevealed) return preRevealBaseURI;
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    /**
     * @notice Freezes the base URI forever
     */
    function freeze() external onlyOwner {
        require(!isFrozen, "42069");
        isFrozen = true;
    }

    /**
     * @notice Sets the base URI of the NFT
     * @param _baseURI A base uri
     */
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        require(!isFrozen, "42069");
        baseURI = _baseURI;
    }

    /**
     * @notice A toggle switch for a reveal
     */
    function toggleRevealed() public onlyOwner {
        isRevealed = !isRevealed;
    }

    /**
     * @notice Sets the max mints per wallet
     * @param _maxPerWallet The max per wallet (Keep mind its +1 n)
     */
    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    /**
     * @notice A toggle switch for pimp claim off
     */
    function triggerPreMintSale(bytes32 _merkleRoot) public onlyOwner {
        isPimpClaimEnabled = false;
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice A toggle switch for public sale
     * @param _maxSupply The max nft collection size
     * @param _maxPerWallet The max per wallet allocation
     */
    function triggerPublicSale(uint256 _maxSupply, uint256 _maxPerWallet)
        external
        onlyOwner
    {
        delete merkleRoot;
        maxSupply = _maxSupply;
        maxPerWallet = _maxPerWallet;
    }

    /**
     * @notice Sets the prereveal cid
     * @param _preRevealBaseURI The pre-reveal URI
     */
    function setPreRevealBaseURI(string memory _preRevealBaseURI)
        external
        onlyOwner
    {
        preRevealBaseURI = _preRevealBaseURI;
    }

    /**
     * @notice Sets the merkle root for the mint
     * @param _merkleRoot The merkle root to set
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice Sets the max supply
     * @param _maxSupply The max nft collection size. After frozen cannot be set again.
     */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(!isFrozen, "42069");
        maxSupply = _maxSupply;
    }

    /**
     * @notice Collects the reserve mints for the PPH vault. One time operation.
     * @param amount The number of mints to collect
     */
    function collectReserves(uint256 amount) external onlyOwner {
        require(!isCollected, "96");
        _safeMint(msg.sender, amount);
        isCollected = true;
    }
}
