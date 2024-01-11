// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./ERC721A.sol";

contract BurgersAddictsNFT is ERC721A, Ownable, ReentrancyGuard {

    string public baseURI = "ipfs://QmPErHJdTWLFYpwK7s2D6cL4PcRyHBXHpjR9DAxCDRfhkB/";
    string public baseExtension = ".json";
    uint256 public maxPerTx = 5;
    uint256 public maxSupply = 999;

    string public hiddenMetadataUri;
    bool public revealed = false;

    constructor() ERC721A("Burgers Addicts", "BA"){
        setHiddenMetadataUri("ipfs://QmeeWESgWm9Q8us7v1DnCsKX6DtiHj3ox53m8yqbstymPL");
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)

    {
        require(
        _exists(_tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI,Strings.toString(_tokenId) , baseExtension))
            : "";
    }

    function mint(uint256 amount) public
    {
        require(totalSupply() + amount <= maxSupply,"too many!");
        require( amount <= maxPerTx, "Max per TX reached.");
        _safeMint(msg.sender, amount);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setMaxPerTx(uint256 maxPerTx_) external onlyOwner {
        maxPerTx = maxPerTx_;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

}