//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract TrustLabDeed is ERC721A, Ownable {
    bytes32 public merkleRoot;

    string  public baseURI;
    uint256 public maxSupply = 10000;
    uint256 public mintStateFlag = 1;

    mapping(address => uint256) public quantityMinted;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor()
    ERC721A ("Trust Lab Deed", "TLD") {
    }

    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 1;
    }

    function mint(bytes32[] calldata proof) public payable callerIsUser {
        require(canMint(msg.sender, proof), "Failed wallet verification");
        require(quantityMinted[msg.sender] & mintStateFlag == 0, "already mint");
        require(totalSupply() + 1 <= maxSupply,"sold out");
        quantityMinted[msg.sender] = quantityMinted[msg.sender] ^ mintStateFlag;
        _safeMint(msg.sender, 1);
    }

    function canMint(address account, bytes32[] calldata proof) public view returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(account)));
    }

    function getMintedForAddress(address account) public view returns (uint256) {
        return quantityMinted[account];
    }

    function setMerkleRootAndFlag(bytes32 _merkleRoot,uint256 flag) public onlyOwner {
        merkleRoot = _merkleRoot;
        mintStateFlag = flag;
    }

    function withdraw() public onlyOwner {
        uint256 sendAmount = address(this).balance;

        address h = payable(msg.sender);

        bool success;

        (success, ) = h.call{value: sendAmount}("");
        require(success, "Transaction Unsuccessful");
    }
}