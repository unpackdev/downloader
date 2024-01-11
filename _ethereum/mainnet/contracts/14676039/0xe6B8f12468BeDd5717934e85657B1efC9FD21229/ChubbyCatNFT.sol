// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract ChubbyCatNFT is Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint;

    /// Modify
    uint public cost = 0.05 ether;
    uint public maxSupply = 2500;
    uint public maxMintPerAddress = 10;

    bool public isMintActive;
    bool public isRevealed;

    string public baseURI;
    string public baseExtension = ".json";

    address internal immutable WeCareCharityWallet = 0xfE4abecf0480CdD528012226054DDB0A3dA18106;

    // OpenSea Proxy
    // Rinkeby : 0xf57b2c51ded3a29e6891aba85459d600256cf317
    // Mainnet: 0xa5409ec958c83c3f309868babaca7c86dcb077c1
    address internal proxyAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    mapping(address => bool) public projectProxy;

    modifier checkLimit(uint256 _amount) {
        require(_amount > 0, "Invalid mint amount!");
        require(balanceOf(msg.sender) + _amount <= maxMintPerAddress, "max NFT per address exceeded");
        require(totalSupply() + _amount <= maxSupply, "Max supply exceeded!");
        _;
    }

    modifier checkPrice(uint256 _mintAmount) {
        require(msg.value >= _getPrice(_mintAmount), "Insufficient funds!");
        _;
    }

    modifier whenMintActive() {
        require(isMintActive, "Minting is not active!");
        _;
    }

    modifier notContract() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /// Modify
    constructor() ERC721A("Chubby Cat NFT", "CCN") {
        baseURI = "ipfs://QmdYvSxowc2vtKnpQfduucQKeNndyHy8K7oRafGfVS6cc4/secret.json";
    }

    /// Modify
    function mint(uint256 _amount) external payable checkLimit(_amount) checkPrice(_amount) whenMintActive notContract nonReentrant {
        _safeMint(msg.sender, _amount);
    }

    function _getPrice(uint256 quantity) internal view returns (uint256){
        return cost * quantity;
    }
    /// Modify

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function gift(uint[] calldata _quantity, address[] calldata _recipient) external onlyOwner {
        require(_quantity.length == _recipient.length, "Provide quantities and recipients" );
        
        uint totalQuantity;
        uint256 _totalSupply = totalSupply();
        for(uint i = 0; i < _quantity.length; ++i) {
            totalQuantity += _quantity[i];
        }

        require(_totalSupply + totalQuantity <= maxSupply, "Not enough supply!" );
        for(uint i = 0; i < _recipient.length; ++i) {
            _safeMint(_recipient[i], _quantity[i]);
        }
    }

     function setSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setCost(uint256 _cost) external onlyOwner {
        cost = _cost;
    }

    function setBaseURI(string calldata _baseUri) external onlyOwner {
        baseURI = _baseUri;
    }

    function setMaxMint(uint _maxMint) external onlyOwner {
        maxMintPerAddress = _maxMint;
    }

    function tokenURI(uint _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
    
        if (!isRevealed) {
            return baseURI;
        }

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString(), baseExtension)) : "";
    }

    function numberMinted(address _owner) external view returns (uint) {
        return _numberMinted(_owner);
    }

    function getOwnershipData(uint256 _tokenId) external view returns (TokenOwnership memory) {
        return _ownershipOf(_tokenId);
    }

    function toggleActive() external onlyOwner {
        isMintActive = !isMintActive;
    }

    function toggleReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        //Free listing on OpenSea by granting access to their proxy wallet. This can be removed in case of a breach on OS.
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator || projectProxy[operator]) return true;
        return super.isApprovedForAll(_owner, operator);
    }

    function withdraw() external onlyOwner {
        (bool wcr, ) = payable(WeCareCharityWallet).call{value: address(this).balance * 5 / 100}("");
        require(wcr);
        
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}

contract OwnableDelegateProxy { }

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}