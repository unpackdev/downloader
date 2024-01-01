// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ERC2981.sol";

contract BlindApeYachtClub is ERC721A, ERC2981, Ownable {

    uint256 public maxFree = 3;

    uint256 public maxPaid = 50;

    uint256 public maxSupply = 4269;

    uint256 public cost = 0.002 ether;

    bool public mintingOpen = false;

    string public baseURI;

    mapping(address => bool) public freeMinted;

    mapping(address => uint256) public paidMinted;

    constructor() ERC721A("BlindApeYachtClub", "BAYC") {
        setBaseURI("ipfs://QmWbyQLH8qb9LaPZuLMTpxK7iSxiGjShvmw4P5sxocHCkp/");
        _setDefaultRoyalty(owner(), 600);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function mintFree() public {
        require(totalSupply() + 3 <= maxSupply, "Not enough apes left!");
        require(freeMinted[msg.sender] == false, "Free apes already claimed");
        require(mintingOpen, "Have patience degen!");

        freeMinted[msg.sender] = true;
        _mint(msg.sender, 3);
    }

    function mintPaid(uint256 amount) public payable {
        require(totalSupply() + amount <= maxSupply, "Not enough apes left!");
        require(paidMinted[msg.sender] + amount <= maxPaid, "Max amount of apes minted!");
        require(msg.value == amount * cost, "Incorrect ether value!");
        require(mintingOpen, "Have patience degen!");

        paidMinted[msg.sender] += amount;
        _mint(msg.sender, amount);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : '';
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return
        ERC721A.supportsInterface(interfaceId) ||
        ERC2981.supportsInterface(interfaceId) ||
        super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory newURI) public onlyOwner {
        baseURI = newURI;
    }

    function openMinting() public onlyOwner {
        // Reserve 69 apes for marketing purposes
        _mint(msg.sender, 69);
        mintingOpen = !mintingOpen;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }
}
