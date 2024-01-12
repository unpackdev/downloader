// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./Pausable.sol";
import "./MerkleProof.sol";
import "./IKeyGateway.sol";

contract HedgePay is ERC721A, Ownable, Pausable {
    uint256 public maxSupply = 1000;

    uint256 public keyAmountPrice = 10;
    uint256 public publicPrice = 0.09 ether;
    uint256 public whitelistPrice = 0 ether;

    bool public isKeySaleEnabled = true;
    bool public isPublicSaleEnabled = true;
    bool public isWhitelistSaleEnabled = true;

    mapping(address => uint256) public amountMintedWhitelist;
    uint256 public maxMintableWhitelist = 1;

    mapping(address => uint256) public amountMintedPublic;
    uint256 public maxMintablePublic = 8;

    string private baseURI;
    bytes32 merkleRoot;

    IKeyGateway keyGateway;

    modifier isWhitelisted(address _wallet, bytes32[] calldata _proof) {
        bytes32 leaf = keccak256(abi.encodePacked(_wallet));
        require(
            MerkleProof.verify(_proof, merkleRoot, leaf),
            "Wallet is not whitelisted"
        );
        _;
    }

    modifier isUnderMaxSupply(uint256 _amount) {
        require(
            totalSupply() + _amount <= maxSupply,
            "Max supply has been reached"
        );
        _;
    }

    constructor() ERC721A("Hedge Pay by Hedge Heroes", "HPHH") {
        _mint(msg.sender, 50);
        _pause();
    }

    function mintFromKey(
        uint256 _amount,
        address[] memory _collections,
        uint256[] memory _nfts
    ) external payable whenNotPaused isUnderMaxSupply(_amount) {
        require(isKeySaleEnabled, "Key Sale is not active");

        keyGateway.useNfts(
            keyAmountPrice * _amount,
            _collections,
            _nfts,
            msg.sender
        );

        _mint(msg.sender, _amount);
    }

    function mintPublic(uint256 _amount)
        external
        payable
        whenNotPaused
        isUnderMaxSupply(_amount)
    {
        require(isPublicSaleEnabled, "Public Sale is not active");
        require(
            msg.value >= publicPrice * _amount,
            "Amount sent too low. Send more ETH"
        );
        require(
            amountMintedPublic[msg.sender] + _amount <= maxMintablePublic,
            "You are not eligible to mint more in Public"
        );

        _mint(msg.sender, _amount);

        amountMintedPublic[msg.sender] = amountMintedPublic[msg.sender] + _amount;
    }

    function mintWhitelist(uint256 _amount, bytes32[] calldata _proof)
        external
        payable
        whenNotPaused
        isUnderMaxSupply(_amount)
        isWhitelisted(msg.sender, _proof)
    {
        require(isWhitelistSaleEnabled, "Whitelist Sale is not active");
        require(
            msg.value >= whitelistPrice * _amount,
            "Amount sent too low. Send more ETH"
        );
        require(
            amountMintedWhitelist[msg.sender] + _amount <= maxMintableWhitelist,
            "You are not eligible to mint more in Whitelist"
        );

        _mint(msg.sender, _amount);

        amountMintedWhitelist[msg.sender] = amountMintedWhitelist[msg.sender] + _amount;
    }

    function airdrop(address[] memory _addresses, uint256 _amount)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _mint(_addresses[i], _amount);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setPaused(bool _paused) external onlyOwner {
        _paused ? _pause() : _unpause();
    }

    function updateSaleStatus(
        bool _isKeySaleEnabled,
        bool _isPublicSaleEnabled,
        bool _isWhitelistSaleEnabled
    ) external onlyOwner {
        isKeySaleEnabled = _isKeySaleEnabled;
        isPublicSaleEnabled = _isPublicSaleEnabled;
        isWhitelistSaleEnabled = _isWhitelistSaleEnabled;
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    function setMaxMintableWhitelist(uint256 _maxMintableWhitelist)
        external
        onlyOwner
    {
        maxMintableWhitelist = _maxMintableWhitelist;
    }

    function setMaxMintablePublic(uint256 _maxMintablePublic)
        external
        onlyOwner
    {
        maxMintablePublic = _maxMintablePublic;
    }

    function setKeyGateway(address _address) external onlyOwner {
        keyGateway = IKeyGateway(_address);
    }

    function setPrice(
        uint256 _keyAmountPrice,
        uint256 _publicPrice,
        uint256 _whitelistPrice
    ) external onlyOwner {
        keyAmountPrice = _keyAmountPrice;
        publicPrice = _publicPrice;
        whitelistPrice = _whitelistPrice;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function withdraw(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }
}
