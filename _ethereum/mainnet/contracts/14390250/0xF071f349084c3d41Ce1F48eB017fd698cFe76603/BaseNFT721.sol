// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";

contract BaseNFT721 is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    string public baseURI = "";
    string public contractURI = "";
    string public baseExtension = ".json";
    uint256 public maxSupply;
    uint256 public maxMintAmount;
    uint256 public cost;
    Counters.Counter _nextTokenId;
    bool paused = false;
    bool revealed = false;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initContractURI,
        uint256 _maxSupply,
        uint256 _maxMintAmount,
        uint256 _cost,
        bool _revealed
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setContractURI(_initContractURI);
        _nextTokenId.increment();
        maxSupply = _maxSupply;
        maxMintAmount = _maxMintAmount;
        cost = _cost;
        revealed = _revealed;
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * public
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function mintTo(address _to) public payable {
        uint256 currentTokenId = _nextTokenId.current();
        require(!paused);
        require(currentTokenId <= maxSupply);

        if (msg.sender != owner()) {
            require(msg.value >= cost);
        }

        _nextTokenId.increment();
        _safeMint(_to, currentTokenId);
    }

    function mintAmount(uint256 _mintAmount) public payable {
        require(!paused);
        require(_mintAmount > 0);
        require(_nextTokenId.current() - 1 + _mintAmount <= maxSupply);

        for (uint256 i = 1; i <= _mintAmount; i++) {
            mintTo(msg.sender);
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

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();

        if (revealed == false) {
            return string(abi.encodePacked(currentBaseURI, "hidden", baseExtension));
        }

        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId), baseExtension)) : "";
    }

    //only owner
    function reveal(bool _state) public onlyOwner {
        revealed = _state;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
        maxMintAmount = _newMaxMintAmount;
    }

    function setContractURI(string memory _newContractURI) public onlyOwner {
        contractURI = _newContractURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function withdraw() public payable onlyOwner {
        (bool os,) = payable(owner()).call{value : address(this).balance}("");
        require(os);
    }
}
