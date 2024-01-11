// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract MetaGearAvatar is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string baseURI;
    string public baseExtension = ".json";
    uint256 public cost;
    uint256 public maxSupply = 10000;
    uint256 public maxMintAmount = 1;
    bool public paused = false;
    address public mintRecipient;
    address public mintCollaborator;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        uint256 _cost,
        address _mintRecipient,
        address _mintCollaborator
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setCost(_cost);
        setMintRecipient(_mintRecipient);
        setMintCollaborator(_mintCollaborator);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(uint256 _mintAmount) public nonReentrant payable {
        uint256 supply = totalSupply();
        require(!paused, "Public minting paused");
        require(_mintAmount > 0, "Minting minimum 1");
        require(_mintAmount <= maxMintAmount, "Minting too much");
        require(supply + _mintAmount <= maxSupply, "NFT max supply reached");

        if (msg.sender != owner()) {
            uint256 price = cost * _mintAmount;
            require(msg.value >= price, "Not enough");
            (payable(mintRecipient)).transfer(price / 2);
            (payable(mintCollaborator)).transfer(price / 2);
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
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

    function giveAway(address _to, uint256 _mintAmount) public onlyOwner {
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "Minting minimum 1");
        require(supply + _mintAmount <= maxSupply, "NFT max supply reached");

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, supply + i);
        }
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setMintRecipient(address _newMintRecipient) public onlyOwner {
        mintRecipient = _newMintRecipient;
    }

    function setMintCollaborator(address _newMintCollaborator) public onlyOwner {
        mintCollaborator = _newMintCollaborator;
    }
    function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
        maxMintAmount = _newMaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }
}
