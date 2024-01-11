// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./MerkleProof.sol";


contract Naminori is ERC1155, Ownable {
    enum SaleStatus{STOPPED, WHITE_LIST, PUBLIC}
    SaleStatus public saleStatus;
    uint256 public tokensRemaining = 300;
    uint256 public maxPublicMintPerTx = 1;
    uint256 public cost = 0 ether;
    uint256 public constant NAMINORI_NFT = 1;
    bytes32 merkleRoot;
    using MerkleProof for bytes32[];
    mapping (address => uint256) public mintCount;

    string public name = "Naminori";
    string public symbol = "Naminori";

    constructor() ERC1155("https://naminori.xyz/metadata/{id}.json") {
        saleStatus = SaleStatus.STOPPED;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setWhitelist(bytes32 listRoot) public onlyOwner {
        merkleRoot = listRoot;
    }

    function startWhitelistSale(bytes32 listRoot) public onlyOwner {
        setWhitelist(listRoot);
        saleStatus = SaleStatus.WHITE_LIST;
    }

    function startPublicSale() public onlyOwner {
        saleStatus = SaleStatus.PUBLIC;
    }

    function stopMint() public onlyOwner {
        saleStatus = SaleStatus.STOPPED;
    }

    modifier whiteList(bytes32 merkleRoot1, bytes32[] memory proof) {
        require(saleStatus == SaleStatus.WHITE_LIST, "Whitelist sale currently unavailable.");
        require(proof.verify(merkleRoot1, keccak256(abi.encodePacked(msg.sender))),"You are not in the list");
        _;
    }

    modifier mintable(uint256 amount) {
        require(amount>0,"Amount must be positive integer.");
        _;
    }

    function mint(uint256 amount) internal {
        _mint(msg.sender, NAMINORI_NFT, amount, "");
        tokensRemaining -= amount;
    }

    function whitelistMint(bytes32[] memory proof) public payable whiteList(merkleRoot, proof) mintable(1) {
        require(mintCount[msg.sender] == 0, "You have already minted");
        mintCount[msg.sender] += 1;
        mint(1);
    }

    function publicMint(uint256 amount) public payable mintable(amount) {
        require(saleStatus == SaleStatus.PUBLIC, "public sale currently unavailable.");
        require(amount <= maxPublicMintPerTx, "Minting limit exceeded");
        require(mintCount[msg.sender] == 0, "You have already minted");
        require(amount <= tokensRemaining,"Exceeds max supply.");
        mintCount[msg.sender] += 1;
        mint(amount);
    }

    function devMint(uint256 amount, address targetAddress) public onlyOwner {
        require(amount <= tokensRemaining);
        _mint(targetAddress, NAMINORI_NFT, amount, "");
        tokensRemaining -= amount;
    }

    function setURI(string memory uri_) public onlyOwner {
        _setURI(uri_);
    }
}
