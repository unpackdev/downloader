// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721AQueryable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

// ░██████╗░██╗░░██╗░█████╗░░██████╗████████╗░░░
// ██╔════╝░██║░░██║██╔══██╗██╔════╝╚══██╔══╝░░░
// ██║░░██╗░███████║██║░░██║╚█████╗░░░░██║░░░░░░
// ██║░░╚██╗██╔══██║██║░░██║░╚═══██╗░░░██║░░░░░░
// ╚██████╔╝██║░░██║╚█████╔╝██████╔╝░░░██║░░░██╗
// ░╚═════╝░╚═╝░░╚═╝░╚════╝░╚═════╝░░░░╚═╝░░░╚═╝ by Alone Architect

// Powered by https://nalikes.com

contract ArtistDrop is ERC721AQueryable, Ownable {
    
    using Strings for uint256;
    
    uint256 public maxSupply = 100;

    uint256 public price = 0.01 ether;
    uint256 public tokenGatedPrice = 0.006 ether;
    uint256 public minMintPerWallet = 5;

    string public hiddenURI;
    string public baseURI;
    string public uriSuffix;
    
    bool public paused = true;
    bool public revealed = false;

    bytes32 public merkleRoot;
    
    constructor() Ownable(msg.sender) ERC721A("GHOST. by Alone Architect", "GHOST.") {}

    //******************************* MODIFIERS

    modifier notPaused() {
        require(!paused, "The contract is paused!");
        _;
    }

    modifier noBots() {
        require(_msgSender() == tx.origin, "No bots!");
        _;
    }

    modifier mintCompliance(uint256 quantity) {
        require(_totalMinted() + quantity <= maxSupply, "Max Supply Exceeded.");
        _;
    }

    //******************************* OVERRIDES

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    //******************************* MINT

    function mint(uint256 quantity) external payable noBots notPaused
        mintCompliance(quantity) {

            require(quantity >= minMintPerWallet, "Quantity below minimum mint.");
            require(msg.value >= price * quantity, "Public: Insufficient funds.");            
    
            _safeMint(_msgSender(), quantity);
    }
    
    function tokenGatedMint(uint256 quantity, bytes32[] calldata proof) external payable noBots notPaused
        mintCompliance(quantity) {

            require(quantity >= minMintPerWallet, "Quantity below minimum mint.");
            require(msg.value >= tokenGatedPrice * quantity, "Allowlist: Insufficient funds.");
            require(checkElligibility(_msgSender(), proof), "Allowlist: Not Elligible.");
            
            _safeMint(_msgSender(), quantity);
    }

    function mintAdmin(address to, uint256 quantity) external onlyOwner mintCompliance(quantity) {
        _safeMint(to, quantity);
    }

    //******************************* ADMIN

    function setMaxSupply(uint256 _supply) external onlyOwner {
        require(_supply >= _totalMinted() && _supply <= maxSupply, "Invalid Max Supply.");
        maxSupply = _supply;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setTokeGatedPrice(uint256 _price) public onlyOwner {
        tokenGatedPrice = _price;
    }

    function setMinMintPerWallet(uint256 _min) public onlyOwner {
        minMintPerWallet = _min;
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

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    //******************************* WITHDRAW

    function withdraw() public onlyOwner {
        
        uint256 balance = address(this).balance;

        bool success;
        (success, ) = payable(0x1f290704CDB8942eB15e831A1C907c1d29467765).call{value: ((balance * 68) / 100)}("");
        require(success, "Transaction 1 Unsuccessful");

        (success, ) = payable(0xF2a28B6c17B7e8C86eF8f5fd785E99d2E4561788).call{value: ((balance * 12) / 100)}("");
        require(success, "Transaction 2 Unsuccessful");

        (success, ) = payable(0x072377fec29Fff72654E0E5B3bA46f69D3d2A9AE).call{value: ((balance * 20) / 100)}("");
        require(success, "Transaction 3 Unsuccessful");
    }

    //******************************* VIEWS

    function tokenURI(uint256 _tokenId) public view virtual override (ERC721A, IERC721A) returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        if (revealed == false) {
            return hiddenURI;
        }

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString(), uriSuffix)) : "";    
    }

    function checkElligibility(address _address, bytes32[] calldata proof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }
}