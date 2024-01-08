//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";


contract NoumenaFloral is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;


    // Token name
    string private _name;
    // Token symbol
    string private _symbol;

    // Max total supply
    uint256 public maxSupply = 10;
    // Max painting name length
    uint256 private _maxImageNameLength = 50;
    bool public storeIsOpen = false;
    // purchase price
    uint256 private _purchasePrice = 40000000000000000 wei;

    // Mapping from image name to its purchased status
    mapping(string => bool) private _namePurchases;

    // Mapping from image name to its token id
    mapping(string => uint256) private _imageNameToTokenId;

    // Token Id to image hash
    mapping(uint256 => string) private _tokenIdToImageHash;

    // Token Id to image name
    mapping(uint256 => string) private _tokenIdToImageName;

    // Token Id to image id
    mapping(uint256 => string) private _tokenIdToImageId;

    constructor(string memory tokenName, string memory symbol) ERC721(tokenName, symbol) {
        _name = tokenName;
        _symbol = symbol;
        _setBaseURI("ipfs://");
    }

    function setBaseURI(string memory newURI) external onlyOwner {
        // _metadataURI = newURI;
        _setBaseURI(newURI);
    }

    function setPurchasePrice(uint256 newPrice) external onlyOwner {
        _purchasePrice = newPrice;
    }

    function tokenSupply() external view returns (uint256) {
        return _tokenIds.current();
    }

    function getMaxSupply() external view returns (uint256) {
        return maxSupply;
    }

    function purchasePrice() external view returns (uint256) {
        return _purchasePrice;
    }

    function isStoreOpen() external view returns (bool) {
        return storeIsOpen;
    }

    function tokenIdForName(string memory _paintingName)
        external
        view
        returns (uint256)
    {
        return _imageNameToTokenId[_paintingName];
    }

    function tokenHashForId(uint256 _tokenId)
        external
        view
        returns (string memory)
    {
        return _tokenIdToImageHash[_tokenId];
    }

    function _mint(
        address _owner,
        string memory _imageName,
        string memory _imageHash
    ) private returns (uint256) {
        _tokenIds.increment();

        uint256 _newTokenId = _tokenIds.current();

        _safeMint(_owner, _newTokenId);

        _namePurchases[_imageName] = true;
        _imageNameToTokenId[_imageName] = _newTokenId;
        _tokenIdToImageHash[_newTokenId] = _imageHash;
        _tokenIdToImageName[_newTokenId] = _imageName;

        if (_newTokenId == maxSupply) {
            storeIsOpen = false;
        }

        return _newTokenId;
    }

    function mint(
        string memory _imageHash,
        string memory _imageName
    ) external payable returns (uint256) {
        require(storeIsOpen, "The store is currently closed");
        require(_tokenIds.current() < maxSupply, "Maximum supply has been reached");
        require(
            bytes(_imageName).length <= _maxImageNameLength,
            "Name of the image is too long"
        );
        require(msg.value >= _purchasePrice, "Insufficient message value");
        require(
            !_namePurchases[_imageName],
            "That named piece has already been purchased"
        );
        uint256 _newTokenId = _mint(
            msg.sender,
            _imageName,
            _imageHash
        );

        return _newTokenId;
    }

    function ownerMint(
        string memory _imageHash,
        string memory _imageName
    ) external onlyOwner returns (uint256) {
        require(_tokenIds.current() < maxSupply, "Maximum supply has been reached");
        require(
            bytes(_imageName).length <= _maxImageNameLength,
            "Name of the image is too long"
        );
        require(
            !_namePurchases[_imageName],
            "That named piece has already been purchased"
        );
        uint256 _newTokenId = _mint(msg.sender, _imageName, _imageHash);

        return _newTokenId;
    }

    function updateMetadataHash(
        uint256 _tokenId,
        string memory _imageHash
    ) external onlyOwner returns (uint256) {
        require(_tokenId <= _tokenIds.current(), "Token has not yet been minted");
        require(_tokenId <= maxSupply, "TokenId id beyond max token bounds");
        
        _tokenIdToImageHash[_tokenId] = _imageHash;

        return _tokenId;
    }

    function updateMaxSupply(uint256 newMax) external onlyOwner returns (uint256) {
        maxSupply = newMax;
        return maxSupply;
    }

    function openStore() external onlyOwner returns (bool) {
        storeIsOpen = true;
        return storeIsOpen;
    }

    function closeStore() external onlyOwner returns (bool) {
        storeIsOpen = false;
        return storeIsOpen;
    }

    function tokenInfo(uint256 _tokenId)
        external
        view
        returns (
            string memory _imageHash,
            string memory _imageName
        )
    {
        return (
            _tokenIdToImageHash[_tokenId],
            _tokenIdToImageName[_tokenId]
        );
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory base = baseURI();
        string memory imageHash = _tokenIdToImageHash[tokenId];
        return
            bytes(base).length > 0
                ? string(abi.encodePacked(base, imageHash))
                : "";
    }

    function withdrawBalance() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawAmountTo(address _recipient, uint256 _amount)
        external
        onlyOwner
    {
        require(address(this).balance >= _amount, "not enough funds");
        payable(_recipient).transfer(_amount);
    }
}
