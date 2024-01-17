pragma solidity ^0.8.7;

import "./Base721.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract BLHZMedel is Base721, ReentrancyGuard {
    uint256 public publicPrice;

    uint256 public publicStartTime;

    uint256 public publicEndTime;

    bytes32 public freeMintRoot;

    uint256 public freeNum;

    uint256 public maxFreeSupply;

    mapping(address => bool) public freeMinted;

    constructor() public ERC721A("BLHZ Medel", "BLHZ Medel") {
        maxSupply = 2100;
        maxFreeSupply = 2100;
        publicPrice = 1 ether;
        publicStartTime = 1667620800;
        publicEndTime = 999999999999;
        defaultURI = "ipfs://bafkreifrwfotkfkzdhyqnc3nbs462jvfy2qh2qxpfh2v3wv7agprbgxxcq";
    }

    function freeMint(bytes32[] calldata _proof) external nonReentrant {
        uint256 _num = 1;
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_proof, freeMintRoot, leaf),
            "Merkle verification failed"
        );
        require(!freeMinted[_msgSender()], "Already free minted");
        require(
            block.timestamp >= publicStartTime &&
                block.timestamp <= publicEndTime,
            "Must in time"
        );
        require(totalSupply() + _num <= maxSupply, "Must lower than maxSupply");
        require(
            freeNum + _num <= maxFreeSupply,
            "Must lower than maxFreeSupply"
        );

        _mint(_msgSender(), _num);
        freeNum += _num;
        freeMinted[_msgSender()] = true;
    }

    function publicMint(uint256 _num) external payable nonReentrant {
        require(
            block.timestamp >= publicStartTime &&
                block.timestamp <= publicEndTime,
            "Must in time"
        );
        require(msg.value >= publicPrice * _num, "Must greater than value");
        require(totalSupply() + _num <= maxSupply, "Must lower than maxSupply");
        _mint(_msgSender(), _num);
    }

    function setSupply(uint256 _maxFreeSupply) external onlyOwner {
        maxFreeSupply = _maxFreeSupply;
    }

    function setRoot(bytes32 _freeMintRoot) external onlyOwner {
        freeMintRoot = _freeMintRoot;
    }

    function setPrice(uint256 _publicPrice) external onlyOwner {
        publicPrice = _publicPrice;
    }

    function setTime(uint256 _publicStartTime, uint256 _publicEndTime)
        external
        onlyOwner
    {
        publicStartTime = _publicStartTime;
        publicEndTime = _publicEndTime;
    }
}
