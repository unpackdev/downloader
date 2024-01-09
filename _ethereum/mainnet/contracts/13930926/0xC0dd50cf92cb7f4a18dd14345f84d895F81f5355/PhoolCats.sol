// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Ownable.sol";

contract PhoolCats is ERC721Enumerable, Pausable, Ownable {
    using Strings for uint256;

    string _baseTokenURI = "https://ipfs.io/ipfs/bafybeigearnrgkohbshj53kysz3hyfdkzjip5ucx27o7lewpr4feiufxce/";
    uint256 private FREE_SUPPLY = 3001;
    uint256 private MAX_SUPPLY = 10000;
    uint256 private _price = 0.02 ether;

    constructor() ERC721("PhoolCat", "PHOOLCATS") {}

    function mint(uint256 num) public payable {
        uint256 supply = totalSupply();
        require(num < 26, "You can mint a maximum of 25 Phool Cats");
        require(supply + num < MAX_SUPPLY, "Exceeds maximum Phool Cats supply");
        require(msg.value >= _price * num, "Ether sent is not correct");

        for (uint256 i; i < num; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function freeMint(uint256 num) public {
        uint256 supply = totalSupply();
        require(num < 26, "You can mint a maximum of 25 Phool Cats");
        require(supply + num < FREE_SUPPLY, "Exceeds maximum free Phool Cats supply");
        for (uint256 i; i < num; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        _price = _newPrice;
    }

    function getPrice() public view returns (uint256) {
        return _price;
    }
    
    function getRemainingFree() public view returns (uint256) {
        uint256 supply = totalSupply();
        return FREE_SUPPLY - supply - 1;
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIds;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");
        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }
}
