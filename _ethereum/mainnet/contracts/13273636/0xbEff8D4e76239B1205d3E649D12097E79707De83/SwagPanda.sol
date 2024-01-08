// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract SwagPanda is ERC721Enumerable, ReentrancyGuard, Ownable {

    uint256 public _currentTokenId = 1;
    uint256 public costToMint = 10000000000000000;
    uint256 public supply = 1001;

    function tokenURI(uint256 tokenId) override public pure returns (string memory) {
        return string(abi.encodePacked("https://swagpanda.s3.amazonaws.com/meta/", Strings.toString((tokenId)), '.json'));
    }

    function claim() payable public nonReentrant {
        require(_currentTokenId < supply, "Out of tokens");
        require(msg.value >= costToMint, 'Less than costToMint');
        _safeMint(_msgSender(), _currentTokenId);
        _currentTokenId++;
    }

    function ownerClaim(address _address) public nonReentrant onlyOwner {
        require(_currentTokenId < supply, "Out of tokens");
        _safeMint(_address, _currentTokenId);
        _currentTokenId++;
    }

    function setCostToMint(uint256 _costToMint) public onlyOwner {
        costToMint = _costToMint;
    }

    function setSupply(uint256 _supply) public onlyOwner {
        supply = _supply;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
      
    constructor() ERC721("SwagPanda", "SwagPanda") Ownable() {
        // Mint the first 2 for the owner on deploy
        ownerClaim(owner());
        ownerClaim(owner());
    }
}