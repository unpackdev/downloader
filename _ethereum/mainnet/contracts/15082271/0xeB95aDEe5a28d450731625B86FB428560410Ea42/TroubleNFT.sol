// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract TroubleNFT is ERC721A, Ownable {
    string  public baseURI;
    uint256 public immutable mintPrice = 0.006 ether;
    uint32 public immutable maxSupply = 10000;
    uint32 public immutable perTxLimit = 10;
    bool public activePublic = false;
    mapping(address => bool) public freeMinted;
    mapping(address => bool) public whiteMinted;
    bytes32 public root;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor()
    ERC721A ("TroubleNFT", "TNFT") {
    }

    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 0;
    }

    function publicMint(uint32 amount) public payable callerIsUser{
        require(totalSupply() + amount <= maxSupply,"sold out");
        require(amount <= perTxLimit,"max 10 amount");
        if(freeMinted[msg.sender])
        {
            require(msg.value >= amount * mintPrice,"insufficient");
        }
        else 
        {
            freeMinted[msg.sender] = true;
            require(msg.value >= (amount-1) * mintPrice,"insufficient");
        }
        _safeMint(msg.sender, amount);
    }

    function rapperMint(bytes32[] calldata proof) public callerIsUser {
        require(canMint(msg.sender,root, proof), "no permission");
        require(!whiteMinted[msg.sender], "already minted");
        require(totalSupply() + 10 <= maxSupply,"sold out");
        whiteMinted[msg.sender] = true;
        _safeMint(msg.sender, 10);
    }

    function devMint() public onlyOwner {
        _safeMint(msg.sender, 50);
    }

    function getMintedFree(address addr) public view returns (bool){
        return freeMinted[addr];
    }

    function canMint(address account, bytes32 merkleRoot, bytes32[] calldata proof) public pure returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(account)));
    }

    function setMerkleRoot(bytes32 merkleRoot) public onlyOwner {
        root = merkleRoot;
    }

    function withdraw() public onlyOwner {
        uint256 sendAmount = address(this).balance;

        address h = payable(msg.sender);

        bool success;

        (success, ) = h.call{value: sendAmount}("");
        require(success, "Transaction Unsuccessful");
    }
}