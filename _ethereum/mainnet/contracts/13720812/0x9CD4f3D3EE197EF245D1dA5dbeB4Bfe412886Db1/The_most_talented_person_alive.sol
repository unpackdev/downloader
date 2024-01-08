// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract The_most_talented_person_alive_collection is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string baseURI;
    string public baseExtension = ".json";
    uint256 public price = 0.50 ether;
    uint256 public maxSupply = 10;
    uint256 public maxMintAmount = 1;
    uint256 public saleStartTimestamp = 1639335600; /**Sun Dec 12 2021 19:00:00 GMT+0000*/
    uint96 public _percentageBasisPoints = 1000; /** 10% */
    bool public paused = false; 
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    constructor(string memory _initBaseURI) ERC721("The most talented person alive collection", "JS") {
        baseURI = _initBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

    function mint(uint256 _mintAmount) external payable {
        uint256 supply = totalSupply();
        require(!paused, "The contract is paused!");
        require(block.timestamp > saleStartTimestamp, "The sale hasn't started yet");
        require(_mintAmount > 0);
        require(_mintAmount <= maxMintAmount);
        require(supply + _mintAmount <= maxSupply);

        if (msg.sender != owner()) {
            require(msg.value >= price * _mintAmount);
        }
        
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }
    
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        require (_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
        return (owner(), (_salePrice * _percentageBasisPoints) / 10000);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        if(interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }

        return super.supportsInterface(interfaceId);
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
        
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require (_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }
    
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function SetPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }
    
    function setRoyaltiesPercentage(uint96 _newPercentageBasisPoints) external onlyOwner {
        require(_newPercentageBasisPoints < 10000, "You can't set this percentage, it's too high");
        require(_newPercentageBasisPoints > 0, "You can't set this percentage, it's too low");
        _percentageBasisPoints = _newPercentageBasisPoints;
    }

    function withdrawAll() external payable onlyOwner {
        (bool succes, ) = payable(owner()).call{value: address(this).balance}("");
        require(succes, "Failed to send Ether");
    }
    
}