// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract GAN is Ownable, ERC721Enumerable {
    
    address public controller;
    string public baseURI;
    uint256 public price;
    address public recipientAddress;
    
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _price
    ) ERC721(_name, _symbol) {
        recipientAddress = msg.sender;
        price = _price;
        baseURI = _uri;
    }
    
    function setPrice(uint256 _value) public onlyOwner {
        price = _value;
    }
    
    function setController(address _controller) public onlyOwner {
        controller = _controller;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }
    
    function setRecipientAddress(address _recipientAddress) public onlyOwner {
        recipientAddress = _recipientAddress;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    modifier onlyControllers() {
        require(controller == msg.sender || owner() == msg.sender, "ERC721: Only Controllers.");
        _;
    }
    
    function mint(
        address _receiver,
        uint256 _tokenId,
        bytes memory _data
    ) public onlyControllers {
        _safeMint(_receiver, _tokenId, _data);
    }
    
    function mintBatch(
        address _receiver,
        uint256[] memory _tokenIds,
        bytes memory _data
    ) public onlyControllers {
        
        for (uint256 j = 0; j < _tokenIds.length; j++) {
            _safeMint(_receiver, _tokenIds[j], _data);
        }
    }
    
    function burn(uint256 _tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(_tokenId);
    }
    
    function burnBatch(uint256[] memory _tokenId) public virtual {
        for (uint256 i = 0; i < _tokenId.length; i++) {
            burn(_tokenId[i]);
        }
    }
}
