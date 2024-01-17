/*
*
*   Tatakai Game NFT
*    
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721AQueryable.sol";
import "./MerkleProof.sol";

contract TatakaiGame is ERC721AQueryable, Ownable { 
    
    using Strings for uint256;

    // Storage
    uint256 public constant MAX_NFTS = 7777;
    uint256 public constant MAX_PUBLIC_PER_TX = 5;

    bytes32 public merkleRoot;
    mapping(address => bool) public claimed;

    string private baseURI;
    bool public presaleStarted;
    bool public publicStarted;

    uint private presalePrice = 25000000000000000; //0.025 ETH
    uint private publicPrice = 35000000000000000; //0.035 ETH

    // Constructor
    constructor() ERC721A("Tatakai Game", "TTG") {
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1; 
    }

    function presaleMint(bytes32[] calldata merkleProof) public payable {
        require(presaleStarted, "PRESALE NOT ACTIVE");
        require(claimed[msg.sender] == false, "already claimed");
        require(MerkleProof.verify(merkleProof, merkleRoot, toBytes32(msg.sender)) == true, "invalid merkle proof");
        require (_totalMinted() + 1 <= MAX_NFTS, "MAX SUPPLY REACHED");
        require (msg.value >= presalePrice, "LOW ETH");

        claimed[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    function publicMint(uint256 amount) public payable {
        require(publicStarted, "PUBLIC SALE NOT ACTIVE");
        require (_totalMinted() + amount <= MAX_NFTS, "MAX SUPPLY REACHED");
        require (amount <= MAX_PUBLIC_PER_TX, "MAX PER TX EXCEEDED");
        require (msg.value >= publicPrice*amount, "LOW ETH");

        _safeMint(msg.sender, amount);
    }

    function toBytes32(address addr) pure internal returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setSaleState(bool saleType, bool newState) public onlyOwner {
        if (saleType) {
            //if true, set presale state
            presaleStarted = newState;
        } else {
            //if false, set public sale state
            publicStarted = newState;
        }
    }
}