//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

contract WhitelistingU is ERC721A, Ownable, ReentrancyGuard {
    // GENERAL VARIABLES
    struct SaleConfig {
        uint64 price;
        uint32 saleKey;
    }

    // Saley Key
    // not started - 0
    // VIP - 1
    // OG - 2
    // AL - 3
    // Public - 4

    struct PresaleConfig {
        uint64 presaleSupply;
        bytes32 merkleRoot;
    }

    // PRESALE VARIABLES
    SaleConfig public saleConfig;
    PresaleConfig public presaleConfig;

    mapping(address => bool) VIPClaimed;

    // PUBLIC SALE
    uint256 public immutable maxBatchSize;
    uint256 public immutable collectionSize;

    constructor(
        uint256 maxBatchSize_,
        uint256 collectionSize_
    ) ERC721A("WhitelistingUPass", "WLUPASS") {
        maxBatchSize = maxBatchSize_;
        collectionSize = collectionSize_;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // MINT FUNCTIONS

    function presaleMint(bytes32[] calldata _merkleProof)
        external
        payable
        callerIsUser
    {

        
        SaleConfig memory config = saleConfig;
        PresaleConfig memory psConfig = presaleConfig;

        uint256 presaleSupply = uint256(psConfig.presaleSupply);
        uint256 saleKey = uint256(config.saleKey);
        uint256 price = uint256(config.price);
           require(
            isPresaleOn(saleKey, presaleSupply),
            "Presale is not active."
        );
        require(msg.value >= price, "Need to send more ETH.");
       

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, psConfig.merkleRoot, leaf),
            "Address not on Whitelist."
        );

        if (saleKey == 1) {
            require(
                numberMinted(msg.sender) + 1 <= 1,
                "This surpases your presale mint limit."
            );
        } else {
            if (VIPClaimed[msg.sender]) {
                require(
                    numberMinted(msg.sender) + 1 <= 2,
                    "This surpases your presale mint limit."
                );
            } else {
                require(
                    numberMinted(msg.sender) + 1 <= 1,
                    "This surpases your presale mint limit."
                );
            }
        }

        require(
            totalSupply() + 1 <= presaleSupply,
            "reached max supply for presale"
        );
        _safeMint(msg.sender, 1);

        if (saleKey == 1) {
            VIPClaimed[msg.sender] = true;
        }
    }

    function publicSaleMint(uint256 quantity) external payable callerIsUser {
        SaleConfig memory config = saleConfig;
        uint256 price = uint256(config.price);
        uint256 saleKey = uint256(config.saleKey);
        require(saleKey == 4, "Public Sale is not Active");
        require(msg.value >= price, "Need to send more ETH.");
        require(
            totalSupply() + quantity <= collectionSize,
            "reached max supply"
        );
        require(quantity <= maxBatchSize, "can not mint this many");
        _safeMint(msg.sender, quantity);
    }

    function isPresaleOn(uint256 presaleKey, uint256 presaleSupply)
        public
        view
        returns (bool)
    {
        return presaleKey > 0 && presaleKey <= 3 && presaleSupply != 0;
    }

    // SETTER FUNCTIONS

    function startVIPMint() external onlyOwner {
        saleConfig.price = 1 ether;
        presaleConfig.presaleSupply = 10;
        saleConfig.saleKey = 1;
    }

    function startOGListMint() external onlyOwner {
        saleConfig.price = 0.08 ether;
        presaleConfig.presaleSupply = 35;
        saleConfig.saleKey = 2;
    }

    function startAllowListMint() external onlyOwner {
        saleConfig.price = 0.1 ether;
        presaleConfig.presaleSupply = 110;
        saleConfig.saleKey = 3;
    }

    function startPublicMint() external onlyOwner {
        saleConfig.price = 0.12 ether;
        presaleConfig.presaleSupply = 10;
        saleConfig.saleKey = 4;
    }

    function endMint() external onlyOwner {
        saleConfig.saleKey = 0;
    }

    function setMerkleRoot(bytes32 _merkleroot) external onlyOwner {
        presaleConfig.merkleRoot = _merkleroot;
    }

    // // METADATA FUNCTIONS

    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    // OWNER/PRIVATE FUNCTIONS

    function devMint(uint256 quantity) external onlyOwner {
        require(
            totalSupply() + quantity <= collectionSize,
            "too many already minted"
        );
        require(
            quantity % maxBatchSize == 0 || quantity <= maxBatchSize,
            "can only mint a multiple of the maxBatchSize or less than the maxBatchSize"
        );

        if (quantity <= maxBatchSize) {
            _safeMint(msg.sender, quantity);
        } else {
            uint256 numChunks = quantity / maxBatchSize;
            for (uint256 i = 0; i < numChunks; i++) {
                _safeMint(msg.sender, maxBatchSize);
            }
        }
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}
