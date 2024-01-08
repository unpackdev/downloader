// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";

//import "./console.sol";

contract Metafam721 is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    string public baseURI;

    string public notRevealedUri;

    //Counters
    Counters.Counter internal _airdrops;
    //Inventory
    uint16 public maxMintAmountPerTransaction = 10;
    uint16 public maxMintAmountPerWallet = 10;
    uint256 public maxSupply = 5000;

    //Prices
    uint256 public cost = 0.06 ether;

    //Utility

    bool public paused = false;
    bool public revealed = false;

    constructor(string memory _baseUrl, string memory _notRevealedUrl)
        ERC721("METAFAM", "MTFM")
    {
        baseURI = _baseUrl;
        notRevealedUri = _notRevealedUrl;
    }

    // public
    function mint(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();

        if (msg.sender != owner()) {
            uint256 ownerTokenCount = balanceOf(msg.sender);

            require(!paused);
            require(_mintAmount > 0, "Mint amount should be greater than 1");
            require(
                _mintAmount <= maxMintAmountPerTransaction,
                "Sorry you cant mint this amount at once"
            );
            require(supply + _mintAmount <= maxSupply, "Exceeds Max Supply");
            require(
                (ownerTokenCount + _mintAmount) <= maxMintAmountPerWallet,
                "Sorry you cant mint more"
            );

            require(msg.value >= cost * _mintAmount, "Insuffient funds");
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function gift(address _to, uint256 _mintAmount) public onlyOwner {
        for (uint256 i = 1; i <= _mintAmount; i++) {
            uint256 supply = totalSupply();
            _safeMint(_to, supply + i);
            _airdrops.increment();
        }
    }

    function totalAirdrops() public view returns (uint256) {
        return _airdrops.current();
    }

    function airdrop(address[] memory _airdropAddresses) public onlyOwner {
        for (uint256 i = 0; i < _airdropAddresses.length; i++) {
            uint256 supply = totalSupply();
            address to = _airdropAddresses[i];
            _safeMint(to, supply + 1);
            _airdrops.increment();
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function getTotalMints() public view returns (uint256) {
        return totalSupply() - _airdrops.current();
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
        if (revealed == false) {
            return notRevealedUri;
        } else {
            string memory currentBaseURI = _baseURI();
            return
                bytes(currentBaseURI).length > 0
                    ? string(
                        abi.encodePacked(currentBaseURI, tokenId.toString())
                    )
                    : "";
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

    function toggleReveal() public onlyOwner {
        revealed = !revealed;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setmaxMintAmountPerTransaction(uint16 _amount) public onlyOwner {
        maxMintAmountPerTransaction = _amount;
    }

    function setMaxMintAmountPerWallet(uint16 _amount) public onlyOwner {
        maxMintAmountPerWallet = _amount;
    }

    function setMaxSupply(uint256 _supply) public onlyOwner {
        maxSupply = _supply;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function togglePause() public onlyOwner {
        paused = !paused;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}
