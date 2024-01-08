// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Deeznuts is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public baseURI = "https://deeznfts.org/api/nft/";
    uint256 public cost = 0.042 ether;
    uint256 public maxSupply = 10000;
    bool public paused = false;

    constructor(
    ) ERC721("Deez Nuts", "DN") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(address _to, uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(!paused && _mintAmount > 0 && supply + _mintAmount <= maxSupply);
        if (msg.sender != owner()) {
            require(msg.value >= cost * _mintAmount);
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, supply + i);
        }
    }

    function giveawayMint(address[] memory _addresses, uint256[] memory amounts)
        public
        onlyOwner
    {
        uint256 supply = totalSupply();
        uint256 _mintAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            _mintAmount += amounts[i];
        }
        require(_addresses.length == amounts.length && _mintAmount > 0 && supply + _mintAmount <= maxSupply);

        for (uint256 j = 0; j < amounts.length; j++) {
            mint(_addresses[j], amounts[j]);
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
            _exists(tokenId)
        );

        return string(abi.encodePacked(_baseURI(), tokenId.toString()));
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}
