// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

contract CactusSoftNFT is ERC721, ERC721Enumerable {
    using Strings for uint256;

    bool public revealed = false;
    // 0 - is not activated, 1 - presale, 2 - public, 3 - deactivated
    uint public state = 0;
    string private baseURI;
    string private preRevealedURI;

    uint256 public price = 0.3 ether;
    uint256 public maxSupply = 200;
    
    mapping(address => bool) private owners;
    mapping(address => bool) private alreadyMinted;

    bytes32 public root; 

    modifier onlyOwners {
        require(owners[msg.sender], "Only owners");
        _;
    }

    constructor() ERC721("CactusSoft+ license", "CS+") {
        owners[msg.sender] = true;
    }

    function mint(bytes32[] memory _proof) public payable returns (uint256){
        require(state != 0, "Minting not active yet");
        require(state != 3, "Minting is stopped");

        uint256 supply = totalSupply();
        require(msg.value == price, "Incorrect ether value");
        require(supply < maxSupply, "NFT limit was reached");
        require(!alreadyMinted[msg.sender], "Each address can mint only once");

        if (state == 1) {
            require(MerkleProof.verify(_proof, root, keccak256(abi.encodePacked(msg.sender))), "Only available for premium minters during presale!");
        }

        uint256 tokenId = supply + 1;

        _safeMint(msg.sender, tokenId);
        alreadyMinted[msg.sender] = true;
        
        return tokenId;
    }

    function setRoot(uint256 _root) public onlyOwners {
        root = bytes32(_root);
    }
    
    function reveal() public onlyOwners {
        revealed = true;
    }

    function activate() public onlyOwners {
        state = 1;
    }

    function endPresale() public onlyOwners {
        state = 2; 
    }

    function deactivate() public onlyOwners {
        state = 3;
    }

    function changeState(uint8 _state) public onlyOwners {
        require(_state < 4, "State number is too high.");
        state = _state;
    }

    function setURIs(string memory _baseURI, string memory _preRevealedURI) public onlyOwners {
        preRevealedURI = _preRevealedURI;
        baseURI = _baseURI;
    }

    function addOwner(address _newOwner) public onlyOwners {
        require(!owners[_newOwner], "Already is an owner");
        owners[_newOwner] = true;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (!revealed) {
            return preRevealedURI;
        }

        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function withdraw() public onlyOwners {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) 
        internal 
        override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    function supportsInterface (bytes4 _interfaceId) public view override (ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }
}