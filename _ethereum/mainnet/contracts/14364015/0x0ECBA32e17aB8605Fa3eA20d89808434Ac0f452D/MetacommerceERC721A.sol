// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./AddressUpgradeable.sol";

import "./ERC721AUpgradeable.sol";
import "./MerkleProof.sol";

interface ICollectionFactory {
    function getProtocolFeeAndRecipient(address _contract) external view returns (uint256, address);
}

contract MetacommerceERC721A is Initializable, ERC721AUpgradeable, OwnableUpgradeable {
    using StringsUpgradeable for string;
    using AddressUpgradeable for address;

    bytes32                  public             merkleRoot;
    bool                     public             revealed;
    bool                     public             whitelistActive;
    string                   public             baseURI;
    uint256                  public             MAX_SUPPLY;
    uint256                  public             MAX_PER_WALLET;
    uint256                  public             MAX_WHITELIST;
    uint256                  public             MAX_PER_TX;
    uint256                  public             priceInWei;
    uint256                  public             priceWhitelist;
    bool                     public             paused;
    ICollectionFactory       public immutable   collectionFactory;

    constructor(address _collectionFactory) {
        require(_collectionFactory.isContract(), "CollectionFactory: _collectionFactory is not a contract");
        collectionFactory = ICollectionFactory(_collectionFactory);
    }

    function initialize(
        address payable _owner,
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        uint256 _priceInWei,
        uint256 _priceWhitelist,
        uint256 _maxSupply,
        uint256 _maxPerWallet,
        uint256 _maxWhitelist,
        bool _revealed,
        bool _whitelistActive
    ) external initializer {
        __ERC721A_init(_name, _symbol);
        __Ownable_init_unchained();
        transferOwnership(_owner);
        baseURI = _baseURI;
        priceInWei = _priceInWei;
        priceWhitelist = _priceWhitelist;
        MAX_SUPPLY = _maxSupply;
        MAX_PER_WALLET = _maxPerWallet;
        MAX_WHITELIST = _maxWhitelist;
        revealed = _revealed;
        whitelistActive = _whitelistActive;
        paused = true;
        MAX_PER_TX = 10;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function setLimits(uint256 _maxPerWallet, uint256 _maxPerTx) public onlyOwner {
        MAX_PER_WALLET = _maxPerWallet;
        MAX_PER_TX = _maxPerTx;
    }

    function setWhitelistPriceAndLimit(uint256 _price, uint256 _maxWhitelist) public onlyOwner {
        priceWhitelist = _price;
        MAX_WHITELIST = _maxWhitelist;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token.");
        return revealed ? (bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, StringsUpgradeable.toString(_tokenId)))
                : "") : string(abi.encodePacked(baseURI));
    }

    function collectReserves(uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds max supply.");
        _safeMint(msg.sender, amount);
    }

    function reveal(string memory revealedURI) external onlyOwner {
        require(!revealed, "Already revealed.");
        baseURI = revealedURI;
        revealed = true;
    }

    function setWhitelistActive(bool _whitelistActive) external onlyOwner {
        whitelistActive = _whitelistActive;
    }

    function pause(bool _state) external onlyOwner {
        paused = _state;
    }

    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot) external onlyOwner {
        merkleRoot = _whitelistMerkleRoot;
    }

    function _leaf(address account, uint256 dummy) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(dummy, account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function whitelistMint(uint256 amount, uint256 dummy, bytes32[] calldata proof) public payable callerIsUser {
        require(!paused, "Contract is paused.");
        require(whitelistActive, "Whitelist sale is over.");
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds max supply.");
        require(_numberMinted(msg.sender) + amount <= MAX_WHITELIST, "Exceeds max per whitelist.");
        require(_verify(_leaf(msg.sender, dummy), proof), "Invalid Merkle Tree proof supplied.");
        require(amount * priceWhitelist == msg.value, "Invalid funds provided.");

        _safeMint(msg.sender, amount);

        (uint256 _protocolFee, address _protocolFeeRecipient) = collectionFactory.getProtocolFeeAndRecipient(address(this));
        (bool success, ) = payable(_protocolFeeRecipient).call{value: msg.value * _protocolFee / 10000}("");
        require(success);
    }

    function mint(uint256 amount) public payable callerIsUser {
        require(!paused, "Contract is paused.");
        require(!whitelistActive, "Whitelist sale is not over yet.");
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds max supply.");
        require(amount <= MAX_PER_TX, "Exceeds max per transaction.");
        require(_numberMinted(msg.sender) + amount <= MAX_PER_WALLET, "Exceeds max per wallet.");
        require(amount * priceInWei == msg.value, "Invalid funds provided.");

        _safeMint(msg.sender, amount);

        (uint256 _protocolFee, address _protocolFeeRecipient) = collectionFactory.getProtocolFeeAndRecipient(address(this));
        (bool success, ) = payable(_protocolFeeRecipient).call{value: msg.value * _protocolFee / 10000}("");
        require(success);
    }
    
    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}