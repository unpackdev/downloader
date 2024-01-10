// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "Ownable.sol";
import "ERC721A.sol";
import "MerkleProof.sol";
import "ReentrancyGuard.sol";

contract GenesisBouncingBall is Ownable, ERC721A, ReentrancyGuard {
    string private _baseTokenURI;
    uint16 public supply = 1000;

    struct SaleConfig {
        bytes32 merkleRoot;
        uint256 price;
        uint16 maxMint;
        uint256 time;
    }
    // Mapping between tier and config
    // Ex. {'dev': SaleConfig()}
    mapping(string => SaleConfig) public tierToConfig;

    constructor() ERC721A("Genesis Bouncing Ball", "BALL") {}

    event Created(address indexed to, uint256 amount);

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // Base URI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // Setters
    function setBaseURI(string calldata baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setConfig(
        string calldata tier,
        bytes32 merkleRoot,
        uint256 price,
        uint16 maxMint,
        uint256 time
    ) public onlyOwner {
        tierToConfig[tier] = SaleConfig(merkleRoot, price, maxMint, time);
    }

    // Mint
    function tierMint(
        string calldata tier,
        uint16 numToMint,
        bytes32[] calldata merkleProof
    ) external payable isMintValid(tier, numToMint) callerIsUser {
        SaleConfig storage config = tierToConfig[tier];
        uint256 price = config.price;
        bytes32 merkleRoot = config.merkleRoot;
        uint16 maxMint = config.maxMint;
        uint256 time = config.time;

        require(time > 0 && block.timestamp > time, "Invalid mint time");
        require(msg.value > 0, "Value has to be above 0");
        require(
            msg.value == price * numToMint,
            "Incorrect ETH sent: check price and number to mint"
        );
        require(
            MerkleProof.verify(
                merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Leaf node could not be verified, check proof."
        );
        _safeMint(msg.sender, numToMint);
        emit Created(msg.sender, numToMint);
    }

    function devMint(string calldata tier, uint16 numToMint)
        external
        onlyOwner
        isMintValid(tier, numToMint)
        callerIsUser
    {
        require(numToMint % 5 == 0, "Not a multiple of 5");
        for (uint32 i = 0; i < numToMint / 5; i++) {
            _safeMint(msg.sender, 5);
        }
        emit Created(msg.sender, numToMint);
    }

    // Dev
    function withdraw() public onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    // Modifiers
    modifier isMintValid(string calldata tier, uint16 numToMint) {
        SaleConfig storage config = tierToConfig[tier];
        uint16 maxMint = config.maxMint;

        require(
            totalSupply() + numToMint < supply + 1,
            "Not enough remaining for mint amount requested"
        );
        require(
            numberMinted(msg.sender) + numToMint < maxMint + 1,
            "Too many minted"
        );
        require(numToMint > 0, "Quantity needs to be more than 0");
        _;
    }
}
