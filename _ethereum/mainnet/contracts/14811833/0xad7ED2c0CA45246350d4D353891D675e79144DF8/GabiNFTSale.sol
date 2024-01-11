// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

enum SaleStage {
    None,
    whitelist,
    publicSale
}

interface NFT {
    function mint(address to) external;
}

contract GabiNFTSale is Ownable, ReentrancyGuard {
    using Strings for uint256;
    using MerkleProof for bytes32[];

    uint256 public whitelistSaleStartTime = 1653111000; // 5/21 1:30pm
    uint256 public whitelistSaleEndTime = whitelistSaleStartTime + 1 days;
    uint256 public whitelistSaleAllocatedQuantity = 120;
    uint256 public publicSaleStartTime = whitelistSaleEndTime + 30 minutes;
    uint256 public publicSaleEndTime = publicSaleStartTime + 1 days;
    uint256 public publicSaleMaxPurchaseAmount = 3;
    uint256 public publicSaleAllocatedQuantity = 0;
    uint256 public maxTotalSoldQuantity =
        publicSaleAllocatedQuantity + whitelistSaleAllocatedQuantity;
    uint256 public mintedQuantity = 0;
    uint256 public whitelistMintPrice = 0.2 ether;
    uint256 public publicSaleMintPrice = 0.24 ether;

    bytes32 private _whitelistMerkleRoot;

    address public GabiNFTAddress;
    mapping(address => bool) public whitelistPurchased;

    constructor(address _GabiNFTAddress) {
        GabiNFTAddress = _GabiNFTAddress;
    }

    /* ************** */
    /* USER FUNCTIONS */
    /* ************** */

    function remainingCount() public view returns (uint256) {
        SaleStage currentStage = getCurrentActiveSaleStage();
        if (currentStage == SaleStage.whitelist) {
            return whitelistSaleAllocatedQuantity - mintedQuantity;
        } else if (currentStage == SaleStage.publicSale) {
            return maxTotalSoldQuantity - mintedQuantity;
        } else {
            return 0;
        }
    }

    // @notice This function returns the current active sale stage
    // @notice 0: NONE, 1: First Whitelist Sale, 2: Public Sale
    function getCurrentActiveSaleStage() public view returns (SaleStage) {
        bool whitelistSaleIsActive = (block.timestamp >
            whitelistSaleStartTime) && (block.timestamp < whitelistSaleEndTime);
        if (whitelistSaleIsActive) {
            return SaleStage.whitelist;
        }
        bool publicSaleIsActive = (block.timestamp > publicSaleStartTime) &&
            (block.timestamp < publicSaleEndTime);
        if (publicSaleIsActive) {
            return SaleStage.publicSale;
        }
        return SaleStage.None;
    }

    function mint(bytes32[] calldata proof, uint256 numberOfTokens)
        external
        payable
        nonReentrant
    {
        require(tx.origin == msg.sender, "contracts not allowed to mint");
        SaleStage currentActiveSaleStage = getCurrentActiveSaleStage();
        require(
            currentActiveSaleStage != SaleStage.None,
            "no active sale right now"
        );
        require(numberOfTokens > 0, "numberOfTokens cannot be 0");
        if (currentActiveSaleStage == SaleStage.whitelist) {
            _mintwhitelist(proof, numberOfTokens);
        } else if (currentActiveSaleStage == SaleStage.publicSale) {
            _mintpublicSale(numberOfTokens);
        }
    }

    function _mintwhitelist(bytes32[] calldata proof, uint256 numberOfTokens)
        internal
    {
        require(
            msg.value == whitelistMintPrice * numberOfTokens,
            "sent ether value incorrect"
        );
        require(!whitelistPurchased[msg.sender], "whitelistPurchased already");
        require(
            proof.verify(
                _whitelistMerkleRoot,
                keccak256(abi.encodePacked(msg.sender, numberOfTokens))
            ),
            "failed to verify first WL merkle root"
        );
        require(numberOfTokens <= remainingCount(), "whitelist sold out");
        whitelistPurchased[msg.sender] = true;
        mintedQuantity += numberOfTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            NFT(GabiNFTAddress).mint(msg.sender);
        }
    }

    function _mintpublicSale(uint256 numberOfTokens) internal {
        require(
            msg.value == publicSaleMintPrice * numberOfTokens,
            "sent ether value incorrect"
        );
        require(numberOfTokens <= remainingCount(), "public sale sold out");
        require(
            numberOfTokens <= publicSaleMaxPurchaseAmount,
            "numberOfTokens exceeds publicSaleMaxPurchaseAmount"
        );

        mintedQuantity += numberOfTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            NFT(GabiNFTAddress).mint(msg.sender);
        }
    }

    /* *************** */
    /* ADMIN FUNCTIONS */
    /* *************** */

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        _whitelistMerkleRoot = _merkleRoot;
    }

    function setSaleData(
        uint256 _whitelistSaleStartTime,
        uint256 _whitelistSaleEndTime,
        uint256 _whitelistSaleAllocatedQuantity,
        uint256 _publicSaleStartTime,
        uint256 _publicSaleEndTime,
        uint256 _publicSaleMaxPurchaseAmount,
        uint256 _publicSaleAllocatedQuantity,
        uint256 _maxTotalSoldQuantity,
        uint256 _whitelistMintPrice,
        uint256 _publicSaleMintPrice
    ) external onlyOwner {
        whitelistSaleStartTime = _whitelistSaleStartTime;
        whitelistSaleEndTime = _whitelistSaleEndTime;
        whitelistSaleAllocatedQuantity = _whitelistSaleAllocatedQuantity;
        publicSaleStartTime = _publicSaleStartTime;
        publicSaleEndTime = _publicSaleEndTime;
        publicSaleMaxPurchaseAmount = _publicSaleMaxPurchaseAmount;
        publicSaleAllocatedQuantity = _publicSaleAllocatedQuantity;
        maxTotalSoldQuantity = _maxTotalSoldQuantity;
        whitelistMintPrice = _whitelistMintPrice;
        publicSaleMintPrice = _publicSaleMintPrice;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
