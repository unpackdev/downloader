// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./ERC721.sol";
import "./Counters.sol";

contract NoumenaAIGenesis is Ownable, ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string  public baseURI = "ipfs://";

    uint256 public maxSupply = 1001;
    uint256 public purchasePrice = 0.04 ether;
    uint256 public maxNameLength = 51;
    address public proxyRegistryAddress;

    mapping(string => bool) private _namePurchases; // used names
    mapping(string => uint256) private _imageNameToTokenId; // get id from name
    mapping(uint256 => string) private _tokenIdToIPFSHash; // get ipfs url from id    
    mapping(uint256 => string) private _tokenIdToImageName; // Get name from id

    constructor(address _proxyRegistryAddress) ERC721("Noumena AI: Genesis", "Noumena AI: Genesis") {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function setProxyRegistryAddress(
        address _proxyRegistryAddress
    ) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function setBaseURI(
        string memory newURI
    ) external onlyOwner {
        baseURI = newURI;
    }

    function setPurchasePrice(
        uint256 newPrice
    ) external onlyOwner {
        purchasePrice = newPrice;
    }

    function tokenSupply() external view returns (uint256) {
        return _tokenIds.current();
    }

    function _mint(
        address owner,
        string memory imageName,
        string memory ipfsHash
    ) internal virtual returns (uint256) {
        uint256 supply = _tokenIds.current();
        require(supply + 1 < maxSupply, "Max Noumena minted");
        require(bytes(imageName).length < maxNameLength, "This Noumena's name is too long");
        require(bytes(imageName).length > 0, "This Noumena's name is too short");
        require(!_namePurchases[imageName], "That name has already been used");

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _namePurchases[imageName] = true;
        _imageNameToTokenId[imageName] = newTokenId;
        _tokenIdToIPFSHash[newTokenId] = ipfsHash;
        _tokenIdToImageName[newTokenId] = imageName;

        _safeMint(owner, newTokenId);

        return newTokenId;
    }

    function publicMint(
        string memory ipfsHash,
        string memory imageName
    ) external payable returns (uint256) {
        require(msg.value >= purchasePrice, "Not enough ether sent");
        uint256 _newTokenId = _mint(msg.sender, imageName, ipfsHash);
        return _newTokenId;
    }

    function ownerMint(
        string memory ipfsHash,
        string memory imageName
    ) external onlyOwner returns (uint256) {
        uint256 _newTokenId = _mint(msg.sender, imageName, ipfsHash);
        return _newTokenId;
    }

    function updateIPFSHash(
        uint256 tokenId,
        string memory ipfsHash
    ) external onlyOwner returns (uint256) {
        require(_exists(tokenId), "Non-existant Noumena");
        
        _tokenIdToIPFSHash[tokenId] = ipfsHash;
        return tokenId;
    }

    function updateMaxSupply(
        uint256 newMax
    ) external onlyOwner returns (uint256) {
        maxSupply = newMax;
        return maxSupply;
    }

    function tokenInfo(
        uint256 tokenId
    ) external view returns (string memory ipfsHash, string memory imageName) {
        return (
            _tokenIdToIPFSHash[tokenId],
            _tokenIdToImageName[tokenId]
        );
    }

    function tokenIdForName(
        string memory name
    ) external view returns (uint256) {
        return _imageNameToTokenId[name];
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Non-existant Noumena");
        string memory ipfsHash = _tokenIdToIPFSHash[tokenId];
        return string(abi.encodePacked(baseURI, ipfsHash));
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    function burn(uint256 tokenId) public { 
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved to burn.");
        _burn(tokenId);
    }

    function isApprovedForAll(
        address owner, 
        address operator
    ) public view override returns (bool) {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }
}

contract OwnableDelegateProxy {}
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}