// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract QuiPenguinsCollection is ERC721Enumerable, Ownable {
    using Strings for uint256;

    event AddedToWhiteList(address[] addresses);
    event RemovedFromWhiteList(address[] addresses);

    bool public mintPaused = false;
    string public baseExtension = ".json";
    string public baseURI;
    uint256 public price;
    uint256 public maxAmount;
    uint256 public maxMintAmount;
    mapping(address => bool) public whitelisted;

    constructor(
        string memory _initBaseURI,
        string memory _name,
        string memory _symbol,
        uint256 _price,
        uint256 _maxAmount,
        uint256 _maxMintAmount
    ) ERC721(_name, _symbol) {
        price = _price;
        maxAmount = _maxAmount;
        maxMintAmount = _maxMintAmount;
        baseURI = _initBaseURI;
        mint(msg.sender, 5);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(address _to, uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(!mintPaused, 'mintPaused');
        require(_mintAmount > 0, 'mint amount should be more than 0');
        require(_mintAmount <= maxMintAmount, 'max mint amount 5');
        require(supply + _mintAmount <= maxAmount, 'max collection supply 3000');

        if (msg.sender != owner() && whitelisted[msg.sender] != true) {
            require(msg.value >= price * _mintAmount, 'not enough money');
        }

        if (whitelisted[msg.sender] == true) {
            require(msg.value >= price * (_mintAmount - 1), 'not enough money');
            whitelisted[msg.sender] = false;
            address[] memory users = new address[](1);
            users[0] = msg.sender;
            emit RemovedFromWhiteList(users);
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, supply + i);
        }
    }

    function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
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

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
    }

    function setPrice(uint256 _newPrice) public onlyOwner() {
        price = _newPrice;
    }

    function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner() {
        maxMintAmount = _newMaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        mintPaused = _state;
    }

    function withdraw() public payable onlyOwner {
        (bool success,) = payable(msg.sender).call{value : address(this).balance}("");
        require(success);
    }

    function addWhitelistUsers(address[] memory _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            whitelisted[_users[i]] = true;
        }
        emit AddedToWhiteList(_users);
    }

    function removeWhitelistUsers(address[] memory _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            whitelisted[_users[i]] = false;
        }
        emit RemovedFromWhiteList(_users);
    }
}
