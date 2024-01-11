// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract gtdrinkswtf is ERC721, Ownable, Pausable {
    using Strings for uint256;

    string private baseURI = '';
    uint private maxSupply = 10001;
    uint private mintedSupply = 1;
    uint private basePrice = 0;
    bool public revealed = false;
    string public hiddenMetadataUri = 'ipfs://bafkreidtkzblgar6l6d6pajxtliyioglyppal5kbbh4tu76flmmz3bnthe';

    constructor() ERC721("gtdrinkswtf", "gtdrinkswtf") {
        pause();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdraw(address addr) external onlyOwner {
        payable(addr).transfer(address(this).balance);
    }

    function mint(uint amount) public payable whenNotPaused {
        require(tx.origin == msg.sender, "Contract are not allowed to call");    
        require(amount <= 3, "One TX Max supply 3");

        require(mintedSupply < maxSupply, "Max supply reached");
        require(mintedSupply + amount <= maxSupply, "Exceeds max supply");

        require(msg.value >= basePrice * amount, "Not enough ETH sent");

        mintInner(amount);
    }

    function mintInner(uint amount) internal {
        for (uint i = 0; i < amount; i++) {
            _safeMint(msg.sender, mintedSupply);
            mintedSupply++;
        }
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setBasePrice(uint price) external onlyOwner {
        basePrice = price;
    }

    function getStatus() public view returns (uint[] memory) {
        uint[] memory arr = new uint[](8);
        arr[0] = paused() ? 0 : 1;
        arr[1] = basePrice;
        arr[2] = maxSupply;
        arr[3] = mintedSupply;
        return arr;
    }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString())) : "";
  }
}