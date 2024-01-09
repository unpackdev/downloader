// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract TheVoxelUniverse is ERC721A, Ownable {    
    string public baseURI;

    uint256 public MINT_PRICE = 0.05 ether;

    bool public presaleActive = false;
    bool public publicSaleActive = false;

    uint32 public batchCounter;
    uint32 public BATCH_SIZE = 500;

    mapping(address => mapping(uint => uint)) presaleMintsTracker;
    mapping(address => mapping(uint => uint)) publicSaleMintsTracker;

    mapping(uint => uint) public maxPresaleMintsPerWalletForBatch;
    mapping(uint => uint) public maxPublicMintsPerWalletForBatch;
    mapping(uint => uint) public batchTotalMintsCounter;

    bytes32 public merkleRoot;

    constructor() ERC721A("The Voxel Universe", "VOXU", 10) {
        batchTotalMintsCounter[batchCounter] = 0;

        maxPresaleMintsPerWalletForBatch[batchCounter] = 1;
        maxPublicMintsPerWalletForBatch[batchCounter] = 2;

        merkleRoot = 0x31880a6ff599d4ca8c51bd8632917ec5cb4afa5b95b68ba0e376b0f173a18afd;
        baseURI = "ipfs://bafybeidp2pht7hfdezx2grbvzsvg6dmhxqf4fhehr7hhwfoj4uacgbx3va/";
    }

    function mint(uint numberOfMints) public payable {
        address msgSender = msg.sender;
        require(tx.origin == msgSender, "Only EOA");
        require(publicSaleActive, "Public sale is not active");
        require((batchTotalMintsCounter[batchCounter] + numberOfMints) <= BATCH_SIZE, "Reached max supply for this batch");
        require((publicSaleMintsTracker[msgSender][batchCounter] + numberOfMints) <= maxPublicMintsPerWalletForBatch[batchCounter], "You can't mint more for this batch");
        require((MINT_PRICE * numberOfMints) == msg.value, "Invalid ETH value sent");

        batchTotalMintsCounter[batchCounter] += numberOfMints;
        publicSaleMintsTracker[msgSender][batchCounter] += numberOfMints;

        _safeMint(msgSender, numberOfMints);
    }

    function presaleMint(uint numberOfMints, bytes32[] calldata _merkleProof) public payable {
        address msgSender = msg.sender;
        require(tx.origin == msgSender, "Only EOA");
        require(presaleActive, "Presale is not active");
        require((batchTotalMintsCounter[batchCounter] + numberOfMints) <= BATCH_SIZE, "Reached max supply for this batch");
        require((presaleMintsTracker[msgSender][batchCounter] + numberOfMints) <= maxPresaleMintsPerWalletForBatch[batchCounter], "You can't mint more for this batch");
        require((MINT_PRICE * numberOfMints) == msg.value, "Invalid ETH value sent");

        bytes32 leaf = keccak256(abi.encodePacked(msgSender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof");

        batchTotalMintsCounter[batchCounter] += numberOfMints;
        presaleMintsTracker[msgSender][batchCounter] += numberOfMints;

        _safeMint(msgSender, numberOfMints);
    }

    function gift(address[] calldata destinations) public onlyOwner {
        require((batchTotalMintsCounter[batchCounter] + destinations.length) <= BATCH_SIZE, "Reached max supply for this batch");
        batchTotalMintsCounter[batchCounter] += destinations.length;

        for (uint i = 0; i < destinations.length; i++) {
            _safeMint(destinations[i], 1);
        }
    }

    function setSaleStatus(bool _presale, bool _public) public onlyOwner {
        require(!(_presale == true && _public == true), "Can't both be active");

        presaleActive = _presale;
        publicSaleActive = _public;
    }

    function setMaxLimits(uint _maxPresaleMintsPerWallet, uint _maxPublicSaleMintsPerWallet) public onlyOwner {
        maxPresaleMintsPerWalletForBatch[batchCounter] = _maxPresaleMintsPerWallet;
        maxPublicMintsPerWalletForBatch[batchCounter] = _maxPublicSaleMintsPerWallet;
    }

    function goToNextBatch(uint _maxPresaleMintsPerWallet, uint _maxPublicSaleMintsPerWallet, bytes32 _merkleRoot) public onlyOwner {
        require(totalSupply() % BATCH_SIZE == 0, "Current batch did not mint out yet");
        require(_maxPresaleMintsPerWallet <= 10 && _maxPublicSaleMintsPerWallet <= 10, "Max cannot be more than 10");

        batchCounter++;

        merkleRoot = _merkleRoot;
        batchTotalMintsCounter[batchCounter] = 0;
        maxPresaleMintsPerWalletForBatch[batchCounter] = _maxPresaleMintsPerWallet;
        maxPublicMintsPerWalletForBatch[batchCounter] = _maxPublicSaleMintsPerWallet;

        presaleActive = false;
        publicSaleActive = false;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setBatchSize(uint32 new_batch_size) public onlyOwner {
        BATCH_SIZE = new_batch_size;
    }

    function setMintPrice(uint new_price) public onlyOwner {
        MINT_PRICE = new_price;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}