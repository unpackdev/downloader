// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract PZero is ERC721 , ERC721Enumerable, Ownable {

    string private baseUri;
    bytes32 public _merkleRoot;
    bool public reveal = false;

    bool public preSaleActive = false;
    bool public saleIsActive = false;
    uint16 public  constant MAX_SUPPLY = 5555;
    uint256 public  constant MAX_PRESALE_MINT = 5;
    uint256 public  tokenPrice = 0.07 ether;
    uint256 public  whitelistPrice = 0.04 ether;

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    constructor(string memory _uri) ERC721("Zero Project", "ZERO") {
        baseUri = _uri;
        reserve(5);
    }

    function verify(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
            bytes32 computedHash = leaf;
            for (uint256 i = 0; i < proof.length; i++) {
                bytes32 proofElement = proof[i];

                if (computedHash <= proofElement) {
                    computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
                } else {
                    computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
                }
            }
            return computedHash == root;
        }

    function changeUri(string memory _uri) external onlyOwner {
        baseUri = _uri;
    }

    function revealToken() external onlyOwner {
        reveal = true;
    }

    function activePreSale() external onlyOwner {
        preSaleActive = true;
    }

    function setPrice(uint256 _price) external onlyOwner {
        tokenPrice = _price; 
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        _merkleRoot = _root;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        if (reveal == true) {
            return super.tokenURI(tokenId);
        } else {
            string memory baseURI = _baseURI();
            return string(abi.encodePacked(baseURI, "r", toString(tokenId)));
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function reserve(uint256 n) public onlyOwner {
      uint supply = totalSupply();
      uint i;
      for (i = 0; i < n; i++) {
          _safeMint(msg.sender, supply + i);
      }
    }

    function activeSales() public onlyOwner {
        preSaleActive = false;
        saleIsActive = true;
    }

    function regularMint(uint256 numberOfTokens) external payable {
        uint256 ts = totalSupply();
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(tokenPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");
        require(saleIsActive, "No sale for now");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }
    
    function preMint(bytes32[] calldata _merkleTree, uint256 numberOfTokens) external payable {
        uint256 ts = totalSupply();
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(preSaleActive, "No presale for now");
        require(balanceOf(msg.sender) + numberOfTokens <= MAX_PRESALE_MINT, "Exceeded max token purchase");
        require(verify(_merkleTree, _merkleRoot, leaf), "Not on whitelist");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(whitelistPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}