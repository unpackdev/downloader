// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./MerkleProof.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721AQueryable.sol";
import "./ERC721ABurnable.sol";

/**
 * @title K9Legendz
 * @author @ScottMitchell18
 */
contract K9Legendz is ERC721AQueryable, ERC721ABurnable, Ownable {
    using Strings for uint256;

    // @dev Base uri for the nft
    string private baseURI =
        "ipfs://bafybeialaqge3babzzkzteae2fj6tghjswr6f42sgbjyhefcli4j56ehdu/";

    // @dev The max amount of mints per wallet
    uint256 public maxPerWallet = 101;

    // @dev The price of a mint
    uint256 public price = 0.05 ether;

    // @dev The withdraw address
    address public treasury =
        payable(0x3DE13eDa328D727583Fb503cc8073fB84d8333bc);

    // @dev The total supply of the collection
    uint256 public maxSupply;

    // @dev An address mapping to add max mints per wallet
    mapping(address => uint256) public addressToMinted;

    // @dev The merkle root proof for whitelist
    bytes32 public whitelistMerkleRoot =
        0xc1bce9790246340bda494b168470d76a08dca98a02fbba8a610d338b568d5abe;

    // @dev The whitelist mint state
    bool public isWhitelistMintActive = false;

    // @dev The public mint state
    bool public isPublicMintActive = false;

    constructor() ERC721A("K9Legendz", "K9") {}

    /**
     * @notice Whitelisted minting function which requires a merkle proof
     * @param _proof The bytes32 array proof to verify the merkle root
     */
    function whitelistMint(uint256 _amount, bytes32[] calldata _proof)
        public
        payable
    {
        require(isWhitelistMintActive, "99");
        require(msg.value >= _amount * price, "1");
        require(addressToMinted[_msgSender()] + _amount < maxPerWallet, "3");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_proof, whitelistMerkleRoot, leaf), "4");
        addressToMinted[_msgSender()] += _amount;
        _safeMint(_msgSender(), _amount);
    }

    /**
     * @notice Mints a new k9 legendz token
     * @param _amount The number of tokens to mint
     */
    function mint(uint256 _amount) public payable {
        require(isPublicMintActive, "99");
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
        delete whitelistMerkleRoot;
        isWhitelistMintActive = false;
        isPublicMintActive = true;
        maxSupply = _maxSupply;
        price = 0.07 ether;
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
     * @notice Sets the Whitelist merkle root for the mint
     * @param _whitelistMerkleRoot The merkle root to set
     */
    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot)
        external
        onlyOwner
    {
        whitelistMerkleRoot = _whitelistMerkleRoot;
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
        _safeMint(_to, _amount);
    }

    /**
     * @notice Sets the active state for OG
     * @param _isWhitelistMintActive The og state
     */
    function setWhitelistActive(bool _isWhitelistMintActive)
        external
        onlyOwner
    {
        isWhitelistMintActive = _isWhitelistMintActive;
    }

    /**
     * @notice Sets the active state for OG
     * @param _isPublicMintActive The og state
     */
    function setPublicActive(bool _isPublicMintActive) external onlyOwner {
        isPublicMintActive = _isPublicMintActive;
    }

    /**
     * @notice Sets the treasury recipient
     * @param _treasury The treasury address
     */
    function setTreasury(address _treasury) external onlyOwner {
        treasury = payable(_treasury);
    }

    /**
     * @notice Withdraws funds from contract
     */
    function withdraw() external onlyOwner {
        (bool success, ) = treasury.call{value: address(this).balance}("");
        require(success, "Failed to send to treasury.");
    }
}
