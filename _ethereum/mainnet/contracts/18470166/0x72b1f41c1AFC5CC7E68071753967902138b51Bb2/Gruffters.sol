// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC721.sol";
import "./ERC721Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract Gruffters is ERC721, ERC721Pausable, Ownable, ERC721Burnable {

    using Strings for uint256;

    uint256 public PRICE = 0.04269 ether;
    uint256 public MAX_SUPPLY = 673;

    uint256 public counter = 1;
    bool public isRevealed;
    bool isPublicSale = false;
    bytes32 public merkleRoot;
    string private baseUri;
    string private unrevealedUri;
    mapping(address => bool) public hasMinted;

    constructor(bytes32 _merkleRoot, string memory _unrevealedUri)
        ERC721("Gruffters", "GRFT")
        Ownable(msg.sender)
    {
        merkleRoot = _merkleRoot;
        unrevealedUri = _unrevealedUri;
        isRevealed = false;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mintForTeam() public onlyOwner {
        address team = 0x4730497622bDFd6EAFe1F09Fa22B3A0ACA94a646;
        uint256 auxCounter = counter;
        for (uint i = 0; i < 6; i++) {
            _safeMint(team, auxCounter + i);
        }
    
        counter = auxCounter + 6;
    }

    function whitelistMint(bytes32[] calldata _merkleProof) public payable {
        require(!hasMinted[msg.sender], "Address has already minted");
        require(canMint(_merkleProof), "Address not in whitelist");
        require(msg.value >= PRICE, "Wrong amount");
        require(counter <= MAX_SUPPLY, "Sold out");
        
        _safeMint(msg.sender, counter);
    
        hasMinted[msg.sender] = true;
        counter++;
    }

    function publicMint() public payable {
        require(isPublicSale, "Public sale is not open");
        require(!hasMinted[msg.sender], "Address has already minted");
        require(msg.value >= PRICE, "Wrong amount");
        require(counter <= MAX_SUPPLY, "Sold out");
        
        _safeMint(msg.sender, counter);
    
        hasMinted[msg.sender] = true;
        counter++;
    }

    function canMint(bytes32[] calldata _merkleProof) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Pausable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setUnrevealedURI(string memory _unrevealedUri) public onlyOwner {
        unrevealedUri = _unrevealedUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function setBaseURI(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        if (!isRevealed) return unrevealedUri;
        else return string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }

    function reveal(string memory _baseUri) public onlyOwner {
        isRevealed = true;
        baseUri = _baseUri;
    }

    function openPublicSale() public onlyOwner {
        isPublicSale = true;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}
