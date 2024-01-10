// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC721A.sol";

contract TreasureDrop is ERC721A, Ownable {

    using Strings for uint256;
    mapping (address => uint256) private mintedWL;
    uint256 public maxSupply = 16;
    string private baseURI = "ipfs://QmUu3dwMQ6oG2Nti1T3G7ZnN1a6Pfhb8kMbtzq8hjVygAE/";
    bool public isRevealed;
    mapping (bytes32 => uint) public authHashes;

    event Minted(address caller);

    constructor() ERC721A("TreasureDrop", "TDR") {
        transferOwnership(0x577A2199eA979F87000B0E003fe38D56BEC01F6E);
    }
    
    function mintPublic(string memory key) external {
        require(totalSupply() + 1 <= maxSupply, "Sorry, not enough left!");
        require(checkAutherized(key) > 0, "Sorry, you are not authorized!");
        
        _safeMint(msg.sender, 1);
        authHashes[keccak256(abi.encodePacked(key))] = 0;
        
        emit Minted(msg.sender);
    }
    
    function checkAutherized (string memory key) public view returns (uint){
        return authHashes[keccak256(abi.encodePacked(key))];
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    // ADMIN FUNCTIONS
    function setAuthHashes(uint256[] memory _hashes, uint value) public onlyOwner {
        for (uint i = 0; i < _hashes.length; i++) {
            authHashes[bytes32(_hashes[i])] = value;
        }
    }
    
    function setAuthHash(uint256 _hash, uint value) public onlyOwner {
        authHashes[bytes32(_hash)] = value;
    }

    function flipRevealed(string memory _URI) public onlyOwner {
        baseURI = _URI;
        isRevealed = !isRevealed;
    }

    function setBaseURI(string memory _URI) public onlyOwner {
        baseURI = _URI;
    }

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        maxSupply = _newMaxSupply;
    }

    function withdraw(address payable _to) public onlyOwner {
        payable(_to).transfer(address(this).balance);
    }
    
    receive() external payable {}
}