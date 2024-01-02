// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721AQueryable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

// ██╗░░░░░░█████╗░░██████╗████████╗  ██████╗░███████╗░█████╗░██╗░░░░░███╗░░░███╗░██████╗
// ██║░░░░░██╔══██╗██╔════╝╚══██╔══╝  ██╔══██╗██╔════╝██╔══██╗██║░░░░░████╗░████║██╔════╝
// ██║░░░░░██║░░██║╚█████╗░░░░██║░░░  ██████╔╝█████╗░░███████║██║░░░░░██╔████╔██║╚█████╗░
// ██║░░░░░██║░░██║░╚═══██╗░░░██║░░░  ██╔══██╗██╔══╝░░██╔══██║██║░░░░░██║╚██╔╝██║░╚═══██╗
// ███████╗╚█████╔╝██████╔╝░░░██║░░░  ██║░░██║███████╗██║░░██║███████╗██║░╚═╝░██║██████╔╝
// ╚══════╝░╚════╝░╚═════╝░░░░╚═╝░░░  ╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚══════╝╚═╝░░░░░╚═╝╚═════╝░

// Powered by https://nalikes.com

contract LostRealms is ERC721AQueryable, Ownable {
    
    using Strings for uint256;
    
    uint256 public maxSupply = 2000;
    uint256 public remainingTeamMints = 5;

    uint256 public price = 0.01 ether;

    string public hiddenURI;
    string public baseURI;
    string public uriSuffix;
    
    bool public paused = true; 
    bool public revealed = false;

    address public recipient;
    
    constructor() Ownable(msg.sender) ERC721A("Lost Realms", "$LR") {
        setRecipient(0x266E6fcF795E7Ada402e6787a22910D2D81a4d2b);
    }

    //******************************* MODIFIERS

    modifier notPaused() {
        require(!paused, "The contract is paused!");
        _;
    }

    modifier noBots() {
        require(_msgSender() == tx.origin, "No bots!");
        _;
    }

    modifier mintPriceCompliance(uint256 _mintPrice, uint256 _mintAmount) {
        require(msg.value >= _mintPrice * _mintAmount, "Insufficient funds.");
        _;
    }

    modifier mintCompliance(uint256 quantity) {
        require(_totalMinted() + quantity <= maxSupply - remainingTeamMints, "Max Supply Exceeded.");
        _;
    }

    //******************************* OVERRIDES

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    //******************************* MINT

    function mintPublic(uint256 quantity) external payable noBots notPaused
        mintCompliance(quantity)
        mintPriceCompliance(price, quantity) {

            _safeMint(_msgSender(), quantity);
    }

    function mintReserved(address to, uint256 quantity) external onlyOwner {
        require(_totalMinted() + quantity <= maxSupply, "Reserved: Max Supply Exceeded.");
        require(quantity <= remainingTeamMints, "Exceeds reserved NFTs supply" );
        remainingTeamMints -= quantity;
        _safeMint(to, quantity);
    }

    function mintAdmin(address to, uint256 quantity) external onlyOwner mintCompliance(quantity) {
        _safeMint(to, quantity);
    }

    //******************************* ADMIN

    function setMaxSupply(uint256 _supply) external onlyOwner {
        require(_supply >= _totalMinted() + remainingTeamMints && _supply <= maxSupply, "Invalid Max Supply.");
        maxSupply = _supply;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setUriSuffix(string memory _uriSuffix) external onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setHiddenURI(string memory _hiddenURI) external onlyOwner {
        hiddenURI = _hiddenURI;
    }

    function setRecipient(address newRecipient) public onlyOwner {
        require(newRecipient != address(0), "Cannot be the 0 address!");
        recipient = newRecipient;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    //******************************* WITHDRAW

    function withdraw() public onlyOwner {
        
        require(recipient != address(0), "Cannot be the 0 address!");

        uint256 balance = address(this).balance;
        bool success;
        (success, ) = payable(recipient).call{value: balance}("");
        require(success, "Transaction Unsuccessful");

    }

    //******************************* VIEWS

    function tokenURI(uint256 _tokenId) public view virtual override (ERC721A, IERC721A) returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        if (revealed == false) {
            return hiddenURI;
        }

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString(), uriSuffix)) : "";    
    }
}