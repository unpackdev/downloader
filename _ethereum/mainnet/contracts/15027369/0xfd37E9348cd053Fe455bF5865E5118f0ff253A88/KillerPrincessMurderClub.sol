// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721AQueryable.sol";
import "./ERC721ABurnable.sol";

/**
 * @title Killer Princess Murder Club (KPMC)
 * @author @ScottMitchell18
 */
contract KillerPrincessMurderClub is
    ERC721AQueryable,
    ERC721ABurnable,
    Ownable,
    ReentrancyGuard
{
    using Strings for uint256;

    // @dev Base uri for the nft
    string private baseURI;

    // @dev The max amount of mints per wallet
    uint256 public maxPerWallet = 21;

    // @dev The merkle root proof
    bytes32 public merkleRoot;

    // @dev The price of a mint
    uint256 public price = 0.02 ether;

    // @dev The total supply of the collection
    uint256 public maxSupply;

    // @dev An address mapping to add max mints per wallet
    mapping(address => uint256) public addressToMinted;

    constructor() ERC721A("Killer Princess Murder Club", "KPMC") {
        /*
         * Backfill mints for previous owners (19 owners)
         * Metadata and images will reflect the ownership
         */
        _mint(0x0E255fE54Aa9C18E25BD408D42285121e656e285, 1); // 1
        _mint(0xce0023b9cCCe08dD88d1a59FDeADF309b4CA5799, 1); // 2
        _mint(0xeEb47425f10D216AfA6254eC8fCfE389837991aa, 1); // 6
        _mint(0x65247768eE5F04459238ca2ED7F982393aFAcecb, 1); // 69
        _mint(0xAb16D19DEBd3c64A887461E2003f22Ce3Dd595F3, 1); // 422
        _mint(0x3aC07131de6aBe83d5A0e70b770824cD39718b2D, 1); // 271
        _mint(0x41aCEbb90012ce53aFBA770b032eB910F5C0Ff3F, 1); // 326
        _mint(0x81Ee06B0c2c84d8FfD46D54B4593c7905a123eF8, 1); // 68
        _mint(0xbe946B44a2A775E2886b106cfcC0f6dF2D3bE135, 1); // 866
        _mint(0x118ad9E93ACCBC52772B94AB3Db2256EAb56B71F, 2); // 225, 995
        _mint(0xEFf113a28B34F09b2e9407b84Aac4083Fc287E7d, 1); // 241
        _mint(0xb39Dea3F80A68740e3060d193FddBCBe593e2990, 1); // 246
        _mint(0xA2d16622D97f52ac47632D21358BD703c8dc11A9, 1); // 340
        _mint(0x42DB53bDC473c8bA20FB7ac4468FCBA9Aa1655a9, 1); // 280
        _mint(0xefca376A38b7b4Fb0EF5E9eE604ceDF08026c74e, 1); // 341
        _mint(0x8a6b86cAd5cF85a6DEAcb967EeA5B96A6ED88063, 1); // 874
        _mint(0x173c5ba82c3Ea839a73A5d9A345f6d3C49D928d7, 1); // 693
        _mint(0x508C9B635cEfE1d86c0A3A3CD6e8409c7d97afA4, 3); // 1110, 5, 10
        _mint(0xd50522632B6eD139319D6E6d077066bbfC068Ea4, 4); // 324, 178, 217, 269
    }

    /**
     * @notice Whitelisted minting function which requires a merkle proof
     * @param _proof The bytes32 array proof to verify the merkle root
     */
    function whitelistMint(uint256 _amount, bytes32[] calldata _proof)
        public
        payable
        nonReentrant
    {
        require(msg.value >= _amount * price, "1");
        require(addressToMinted[_msgSender()] + _amount < maxPerWallet, "3");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_proof, merkleRoot, leaf), "4");
        addressToMinted[_msgSender()] += _amount;
        _safeMint(_msgSender(), _amount);
    }

    /**
     * @notice Mints a new kpmc token
     * @param _amount The number of tokens to mint
     */
    function mint(uint256 _amount) public payable nonReentrant {
        require(msg.value >= _amount * price, "1");
        require(totalSupply() + _amount < maxSupply, "2");
        require(addressToMinted[_msgSender()] + _amount < maxPerWallet, "3");
        addressToMinted[_msgSender()] += _amount;
        _safeMint(_msgSender(), _amount);
    }

    /**
     * @notice A toggle switch for public sale
     * @param _maxSupply The max nft collection size
     */
    function triggerPublicSale(uint256 _maxSupply) external onlyOwner {
        delete merkleRoot;
        maxSupply = _maxSupply;
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
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    /**
     * @notice Sets the base URI of the NFT
     * @param _baseURI A base uri
     */
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /**
     * @notice Sets the merkle root for the mint
     * @param _merkleRoot The merkle root to set
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice Sets the collection max supply
     * @param _maxSupply The max supply of the collection
     */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    /**
     * @notice Sets the max mints per wallet
     * @param _maxPerWallet The max per wallet (Keep mind its +1 n)
     */
    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    /**
     * @notice Sets price
     * @param _price price in wei
     */
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    /**
     * @notice Owner Mints
     * @param _to The amount of reserves to collect
     * @param _amount The amount of reserves to collect
     */
    function ownerMint(address _to, uint256 _amount) external onlyOwner {
        require(totalSupply() + _amount < maxSupply, "2");
        _safeMint(_to, _amount);
    }
}
