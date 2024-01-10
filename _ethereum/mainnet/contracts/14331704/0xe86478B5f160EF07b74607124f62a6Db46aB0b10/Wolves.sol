// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

import "./MerkleProof.sol";


contract Wolves is ERC721Enumerable, Ownable {
    using Address for address;

    string private baseURI;
    uint256 public MAX_COUNT = 58;
    bytes32 public root = 0xc26134a842f73ab165c7218546b25d5478cebbd0a27bf4f722a44cc29d38e340; 
    mapping (address => bool) public whitelistClaimed;

    constructor() ERC721("ApexWolves - Collection 0", "APEXWOLVES_0") { }

    function mint() public onlyOwner {
        require(totalSupply() < MAX_COUNT,                      "Genesis Wolves has all been minted");
        _safeMint(msg.sender, totalSupply() + 1);
    }

    function mintReserved(bytes32[] calldata _merkleProof) public {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(!whitelistClaimed[msg.sender],                  "Owner has already minted reserved wolf");
        require(totalSupply() < MAX_COUNT,                      "Genesis Wolves has all been minted");
        require(MerkleProof.verify(_merkleProof, root, leaf),   "Incorrect proof passed to validation");
        whitelistClaimed[msg.sender] = true;
        _safeMint(msg.sender, totalSupply() + 1);
    }

    function walletOfOwner(address owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokensId;
    }

    function setMaxCount(uint256 maxCount) public onlyOwner  {
        MAX_COUNT = maxCount;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setRoot(bytes32 _root) public onlyOwner {
        root = _root;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}