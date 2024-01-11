// SPDX-License-Identifier: UNLICENSED

/*

...                                                                                                           

*/

pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

contract TheEthDeGodsReformed is ERC721A, Ownable {
    bool public saleEnabled;
    uint256 public price;
    string public metadataBaseURL;
    string public PROVENANCE;

    uint256 public MAX_TXN = 7;
    uint256 public MAX_TXN_FREE = 2;
    uint256 public constant FREE_SUPPLY = 5000;
    uint256 public constant PAID_SUPPLY = 5000;
    uint256 public constant MAX_SUPPLY = FREE_SUPPLY+PAID_SUPPLY;

    bytes32 public MerkleRootHex;
    mapping(address => uint256) public whiteListClaimed;

    constructor() ERC721A("The Eth DeGods Reformed", "ETHDEGODS", MAX_TXN) {
        saleEnabled = false;
        price = 0.01 ether;
        MerkleRootHex = 0x0;
    }

    function setBaseURI(string memory baseURL) external onlyOwner {
        metadataBaseURL = baseURL;
    }


    function toggleSaleStatus() external onlyOwner {
        saleEnabled = !(saleEnabled);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        MerkleRootHex = _merkleRoot;
    }


    function setMaxTxn(uint256 _maxTxn) external onlyOwner {
        MAX_TXN = _maxTxn;
    }
    function setMaxTxnFree(uint256 _maxTxnFree) external onlyOwner {
        MAX_TXN_FREE = _maxTxnFree;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return metadataBaseURL;
    }

    function setProvenance(string memory _provenance) external onlyOwner {
        PROVENANCE = _provenance;
    }

    function withdraw() external onlyOwner {
        uint256 _balance = address(this).balance;
        address payable _sender = payable(_msgSender());
        _sender.transfer(_balance);
    }

    function reserve(uint256 num) external onlyOwner {
        require((totalSupply() + num) <= MAX_SUPPLY, "Exceed max supply");
        _safeMint(msg.sender, num);
    }

    function mint(uint256 numOfTokens) external payable {
        require(saleEnabled, "Sale must be active.");
        require(totalSupply() + numOfTokens <= MAX_SUPPLY, "Exceed max supply");
        require(numOfTokens > 0, "Must mint at least 1 token");
        require(numOfTokens <= MAX_TXN, "Cant mint more than 7");
        require(
            (price * numOfTokens) <= msg.value,
            "Insufficient funds to claim."
        );

        _safeMint(msg.sender, numOfTokens);
    }

    function whitelistMint(uint256 numOfTokens,bytes32[] calldata _merkleProof) external payable {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, MerkleRootHex, leaf), "Invalid proof");
        require(whiteListClaimed[msg.sender] + numOfTokens <= MAX_TXN_FREE, "Exceed max whitelist mint");

        require(saleEnabled, "Sale must be active.");
        require(totalSupply() + numOfTokens <= FREE_SUPPLY, "Exceed max supply");
        require(numOfTokens > 0, "Must mint at least 1 token");

        _safeMint(msg.sender, numOfTokens);
    }
}