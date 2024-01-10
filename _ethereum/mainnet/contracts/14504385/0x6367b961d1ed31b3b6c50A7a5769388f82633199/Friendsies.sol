// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// https://friendsies.io, built by @devloper_xyz

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./StringsUpgradeable.sol";

contract Friendsies is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;

    bool public dutchAuctionsActive;
    bool public ghostCloudActive;
    bool public superGoldenCloudActive;

    uint256 public maxSupply;

    uint256 public dutchAuctionsSupply;
    uint256 public dutchAuctionsStartPrice; // in wei
    uint256 public dutchAuctionsReservePrice; // in wei
    uint256 public dutchAuctionsDecreaseAmount; // in wei
    uint256 public dutchAuctionsDecreaseInterval; // in blocks
    uint256 public dutchAuctionsStartBlockNumber;

    bytes32 internal ghostCloudMerkleRoot;
    bytes32 internal superGoldenCloudMerkleRoot;

    string public defaultURI;
    string private contractMetadataURI;

    mapping(bytes32 => bool) internal claimedGhostCloud;
    mapping(bytes32 => bool) internal claimedSuperGoldenCloud;

    /// @dev stores true for tokenIds which were minted for Super Golden Cloud Key holders
    mapping(uint256 => bool) public superGoldenCloudToken;

    uint256 public dutchAuctionsExtensionPeriod; // in blocks - extend auction if current < period
    uint256 public dutchAuctionsExtensionBlocks; // in blocks - extend by blocks if above is true

    event LogMintGhostCloud(address wallet);
    event LogMintSuperGoldenCloud(address wallet);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {} // solhint-disable no-empty-blocks

    function initialize(
        string calldata _defaultURI,
        string calldata _contractMetadataURI
    ) public initializer {
        __ERC721_init("fRiENDSiES", "fRiENDSiES");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        defaultURI = _defaultURI;
        contractMetadataURI = _contractMetadataURI;
        maxSupply = 10000;

        _tokenIdCounter.increment(); // start tokenIds at 1
    }

    /// @notice safeMint mints via the Public Dutch Auctions
    function safeMint(uint256 _amount)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        require(dutchAuctionsActive, "Inactive Auctions");
        require(_amount >= 1, "Min amount is 1");
        require(_amount <= 5, "Max amount is 5");

        if (dutchAuctionsNextDecrease() < dutchAuctionsExtensionPeriod) {
            // extend auction
            dutchAuctionsStartBlockNumber += dutchAuctionsExtensionBlocks;
        }

        uint256 price = dutchAuctionsCurrentPrice();

        // >= will help transactions succeed even when the price just dropped
        // and the website might have still shown the old price.
        require(msg.value >= _amount * price, "Not enough ETH");

        for (uint256 i = 0; i < _amount; i++) {
            require(dutchAuctionsSupply > 0, "out of tokens");
            dutchAuctionsSupply--;
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
        }
    }

    /// @notice safeMintTo airdrops tokens to addresses
    function safeMintTo(address[] calldata _to)
        external
        nonReentrant
        onlyOwner
    {
        for (uint256 i = 0; i < _to.length; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(_to[i], tokenId);
        }
    }

    /// @notice safeMintGhostCloud allows snapshotted Ghost Cloud holders to claim their tokens
    function safeMintGhostCloud(
        uint256 _amount,
        uint256 _price,
        bytes32[] calldata _proof
    ) external payable nonReentrant whenNotPaused {
        require(ghostCloudActive, "not active");
        bytes32 leaf = _genLeaf(msg.sender, _amount, _price);
        require(
            _verify(leaf, _proof, ghostCloudMerkleRoot),
            "Invalid merkle proof"
        );
        require(!claimedGhostCloud[leaf], "already claimed");
        claimedGhostCloud[leaf] = true;
        emit LogMintGhostCloud(msg.sender);
        _safeMintMerkle(_amount, _price, false);
    }

    function hasClaimedGhostCloud(
        address _sender,
        uint256 _amount,
        uint256 _price
    ) external view returns (bool) {
        bytes32 leaf = _genLeaf(_sender, _amount, _price);
        return claimedGhostCloud[leaf];
    }

    /// @notice safeMintSuperGoldenCloud allows snapshotted Super Golden Cloud holders to claim their tokens
    function safeMintSuperGoldenCloud(
        uint256 _amount,
        uint256 _price,
        bytes32[] calldata _proof
    ) external payable nonReentrant whenNotPaused {
        require(superGoldenCloudActive, "not active");
        bytes32 leaf = _genLeaf(msg.sender, _amount, _price);
        require(
            _verify(leaf, _proof, superGoldenCloudMerkleRoot),
            "Invalid merkle proof"
        );
        require(!claimedSuperGoldenCloud[leaf], "already claimed");
        claimedSuperGoldenCloud[leaf] = true;
        emit LogMintSuperGoldenCloud(msg.sender);
        _safeMintMerkle(_amount, _price, true);
    }

    function hasClaimedSuperGoldenCloud(
        address _sender,
        uint256 _amount,
        uint256 _price
    ) external view returns (bool) {
        bytes32 leaf = _genLeaf(_sender, _amount, _price);
        return claimedSuperGoldenCloud[leaf];
    }

    function _safeMintMerkle(
        uint256 _amount,
        uint256 _price,
        bool _superGoldenCloudToken
    ) internal {
        _price = _price * (1 ether / 1000); // finney
        require(msg.value >= _amount * _price, "Not enough ETH");

        for (uint256 i = 0; i < _amount; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            if (_superGoldenCloudToken) {
                superGoldenCloudToken[tokenId] = true;
            }
            _safeMint(msg.sender, tokenId);
        }
    }

    function _safeMint(address _to, uint256 _tokenId) internal override {
        require(totalSupply() < maxSupply, "maxSupply reached");
        super._safeMint(_to, _tokenId);
    }

    function startDutchAuctions() external onlyOwner {
        dutchAuctionsStartBlockNumber = block.number;
        dutchAuctionsActive = true;
    }

    function stopDutchAuctions() external onlyOwner {
        dutchAuctionsActive = false;
    }

    function resetDutchAuctionsStartBlockNumber(uint256 _blockNumber)
        external
        onlyOwner
    {
        dutchAuctionsStartBlockNumber = _blockNumber;
    }

    function setDutchAuction(
        uint256 _startPrice, // wei
        uint256 _reservePrice, // wei
        uint256 _decreaseAmount, // wei
        uint256 _decreaseInterval, // blocks
        uint256 _extensionPeriod, // blocks
        uint256 _extensionBlocks, // blocks
        uint256 _supply
    ) external onlyOwner {
        dutchAuctionsStartPrice = _startPrice;
        dutchAuctionsReservePrice = _reservePrice;
        dutchAuctionsDecreaseAmount = _decreaseAmount;
        dutchAuctionsDecreaseInterval = _decreaseInterval;
        dutchAuctionsExtensionPeriod = _extensionPeriod;
        dutchAuctionsExtensionBlocks = _extensionBlocks;
        dutchAuctionsSupply = _supply;
    }

    function setDutchAuctionsExtension(
        uint256 _extensionPeriod,
        uint256 _extensionBlocks
    ) external onlyOwner {
        dutchAuctionsExtensionPeriod = _extensionPeriod;
        dutchAuctionsExtensionBlocks = _extensionBlocks;
    }

    function setDutchAuctionsSupply(uint256 _supply) external onlyOwner {
        dutchAuctionsSupply = _supply;
    }

    function startGhostCloudDrop(bool _active) external onlyOwner {
        ghostCloudActive = _active;
    }

    function startSuperGoldenCloudDrop(bool _active) external onlyOwner {
        superGoldenCloudActive = _active;
    }

    function setGhostCloudRoot(bytes32 _root) external onlyOwner {
        ghostCloudMerkleRoot = _root;
    }

    function setSuperGoldenCloudRoot(bytes32 _root) external onlyOwner {
        superGoldenCloudMerkleRoot = _root;
    }

    function setDefaultURI(string calldata _uri) external onlyOwner {
        defaultURI = _uri;
    }

    function setMaxSupply(uint256 _supply) external onlyOwner {
        maxSupply = _supply;
    }

    function setTokenURI(uint256[] calldata _tokenId, string[] calldata _uri)
        external
        onlyOwner
    {
        require(_tokenId.length == _uri.length, "len(array) mismatch");
        for (uint256 i = 0; i < _tokenId.length; i++) {
            _setTokenURI(_tokenId[i], _uri[i]);
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setContractMetadataURI(string calldata _uri) external onlyOwner {
        contractMetadataURI = _uri;
    }

    function contractURI() public view returns (string memory) {
        return contractMetadataURI;
    }

    /// @notice returns the number of blocks until the next price decrease
    function dutchAuctionsNextDecrease() public view returns (uint256) {
        uint256 price = dutchAuctionsCurrentPrice();
        if (price <= dutchAuctionsReservePrice) {
            return 0;
        }

        return
            dutchAuctionsDecreaseInterval -
            ((block.number - dutchAuctionsStartBlockNumber) %
                dutchAuctionsDecreaseInterval);
    }

    function dutchAuctionsCurrentPrice() public view returns (uint256) {
        require(dutchAuctionsActive, "Inactive Auctions");

        uint256 decrease = ((block.number - dutchAuctionsStartBlockNumber) /
            dutchAuctionsDecreaseInterval) * dutchAuctionsDecreaseAmount;

        if (decrease > dutchAuctionsStartPrice) {
            // protect from uint256 underflow
            return dutchAuctionsReservePrice;
        }

        uint256 price = dutchAuctionsStartPrice - decrease;

        if (price < dutchAuctionsReservePrice) {
            return dutchAuctionsReservePrice;
        }

        return price;
    }

    function _genLeaf(
        address _account,
        uint256 _amount,
        uint256 _price
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account, _amount, _price));
    }

    function _verify(
        bytes32 _leaf,
        bytes32[] memory _proof,
        bytes32 _root
    ) internal pure returns (bool) {
        require(_leaf.length > 0, "merkle: empty leaf");
        require(_proof.length > 0, "merkle: empty proof");
        require(_root.length > 0, "merkle: empty root");
        return MerkleProofUpgradeable.verify(_proof, _root, _leaf);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    )
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    function _burn(uint256 _tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(_tokenId);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        string memory uri = super.tokenURI(_tokenId);
        if (bytes(uri).length > 0) {
            return uri;
        } else {
            return
                string(
                    abi.encodePacked(
                        defaultURI,
                        StringsUpgradeable.toString(_tokenId),
                        ".json"
                    )
                );
        }
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    /// @notice allows owner to withdraw funds
    function withdraw(address _to, uint256 _value)
        external
        nonReentrant
        onlyOwner
    {
        require(_to != address(0), "zero _to address");
        _transferETH(_to, _value);
    }

    /// @dev Transfer ETH and revert if unsuccessful. Only forward 30,000 gas to the callee.
    function _transferETH(address _to, uint256 _value) private {
        (bool success, ) = _to.call{value: _value, gas: 30_000}(new bytes(0)); // solhint-disable-line avoid-low-level-calls
        require(success, "Transfer failed");
    }
}
