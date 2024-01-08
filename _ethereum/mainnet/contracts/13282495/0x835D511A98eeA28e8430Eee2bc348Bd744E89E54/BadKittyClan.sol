// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
/**
 * @title BadKittyClub contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract BadKittyClan is ERC721Enumerable, Ownable {

    using Strings for uint;

    string public baseURI;
    string public baseExtension = '.json';
    string public provenance = '';
    uint public maxKitties = 1000;
    bool public saleIsActive = false;

    constructor(
        string memory _initBaseURI
        ) ERC721('BadKittyClan', 'BKC') {
        baseURI = _initBaseURI;
        mintKitty(6);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      'ERC721Metadata: URI query for nonexistent token'
    );
    return
      bytes(baseURI).length > 0
        ? string(
          abi.encodePacked(baseURI, tokenId.toString(), baseExtension)
        )
        : '';
  }

    function mintKitty(uint _numKitties) public onlyOwner {
        require(_numKitties > 0, 'You must mint at least 1 Kitty');
        require(totalSupply() + _numKitties <= maxKitties, 'You cannot have more than 1000 Kitties');
        for(uint i = 0; i < _numKitties; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }
    
    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        provenance = _provenanceHash;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}