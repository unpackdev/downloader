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
    function mint(address to, uint256 quantity) external;
}

contract LochySale is Ownable, ReentrancyGuard {
    using Strings for uint256;
    using MerkleProof for bytes32[];

    uint256 public whitelistSaleStartTime = 1649764800; // 4/12 8pm
    uint256 public whitelistSaleEndTime = 1650427200; // 4/20 12pm
    uint256 public whitelistSaleAllocatedQuantity = 888;
    uint256 public publicSaleStartTime = 1650600000; // 4/22 12pm
    uint256 public publicSaleEndTime = publicSaleStartTime + 365 days;
    uint256 public publicSaleMaxPurchaseAmount = 2;
    uint256 public publicSaleAllocatedQuantity = 223;
    uint256 public maxTotalSoldQuantity =
        publicSaleAllocatedQuantity + whitelistSaleAllocatedQuantity;
    uint256 public mintedQuantity = 0;
    uint256 public whitelistMintPrice = 0.288 ether;
    uint256 public publicSaleMintPrice = 0.33 ether;

    bytes32 private _whitelistMerkleRoot;

    address public lochyAddress;
    mapping(address => bool) public whitelistPurchased;

    constructor(address _lochyAddress) {
        lochyAddress = _lochyAddress;
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
        NFT(lochyAddress).mint(msg.sender, numberOfTokens);
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
        NFT(lochyAddress).mint(msg.sender, numberOfTokens);
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
