// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

interface IGenesisNFT {
    function addTokens(uint256 _newTokens) external;
    function ownerMint(address _receiver) external;
    function transferOwnership(address newOwner) external;
}

contract GenesisPrivateSale is Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public tokenPrice = 0.1 ether;
    uint256 public maxSupply = 0;
    bool public saleStarted = false;
    bytes32 public merkleRoot;
    address public nftContract;
    address public withdrawalAddress;

    constructor(address nftContract_) {
        nftContract = nftContract_;
    }

    function purchase(string calldata password, bytes32[] calldata _merkleProof) external payable {
        bytes32 leaf = keccak256(abi.encodePacked(password));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Incorrect proof");

        uint256 tokenIndex = _tokenIdCounter.current() + 1;

        require(tx.origin == msg.sender, "Caller must not be a contract.");
        require(saleStarted, "Private sale has not started.");
        require(msg.value == tokenPrice, "Incorrect Ether amount sent.");
        require(
            tokenIndex <= maxSupply,
            "Minted token would exceed total supply for this private sale."
        );

        _tokenIdCounter.increment();
        
        IGenesisNFT(nftContract).ownerMint(msg.sender);
    }

    function setupNewPrivateSale(bytes32 _newMerkleRoot, uint256 _maxSupply) external onlyOwner {
        merkleRoot = _newMerkleRoot;
        maxSupply = _maxSupply;
        _tokenIdCounter.reset();
    }

    function setNftContractOwner(address _newOwner) external onlyOwner {
        IGenesisNFT(nftContract).transferOwnership(_newOwner);
    }

    function setNftContract(address _nftContract) external onlyOwner {
        nftContract = _nftContract;
    }

    function updateTokenPrice(uint256 _updatedTokenPrice) external onlyOwner {
        tokenPrice = _updatedTokenPrice;
    }

    function toggleSale() external onlyOwner {
        saleStarted = !saleStarted;
    }

    function setWithdrawalAddress(address _withdrawalAddress) external onlyOwner {
        withdrawalAddress = _withdrawalAddress;
    }
    
    function withdrawBalance() external onlyOwner {
        payable(withdrawalAddress).transfer(address(this).balance);
    }
}