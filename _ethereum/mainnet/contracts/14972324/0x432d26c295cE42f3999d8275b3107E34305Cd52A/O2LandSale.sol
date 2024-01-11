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

contract O2LandSale is Ownable, ReentrancyGuard {
    using Strings for uint256;
    using MerkleProof for bytes32[];

    uint256 public whitelistSaleStartTime = 1655517600; // 2022年6月18日星期六 10:00:00
    uint256 public whitelistSaleEndTime = 1655560800; // 2022年6月18日星期六 22:00:00
    uint256 public whitelistSaleAllocatedQuantity = 3000;
    uint256 public publicSaleStartTime = 0;
    uint256 public publicSaleEndTime = 0;
    uint256 public publicSaleAllocatedQuantity = 0;
    uint256 public maxTotalSoldQuantity =
        publicSaleAllocatedQuantity + whitelistSaleAllocatedQuantity;
    uint256 public maxMintQuantityPerTx = 10;
    uint256 public maxMintQuantityPerAddress = 10;
    uint256 public mintedQuantity = 0;
    uint256 public whitelistMintPrice = 0.38 ether;
    uint256 public publicSaleMintPrice = 0.38 ether;

    bytes32 private _whitelistMerkleRoot = 0x33374ab6a2507f826129f3ec4081df2ab4b25728c90253cec626177b05e6d8c4;

    address public o2LandAddress;
    mapping(address => uint256) public whitelistPurchased;
    mapping(address => uint256) public publicSalePurchased;

    constructor(address _o2LandAddress) {
        o2LandAddress = _o2LandAddress;
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

    function mint(
        bytes32[] calldata proof,
        uint256 merkleNumberOfTokens,
        uint256 userSelectedNumberOfTokens
    ) external payable nonReentrant {
        require(tx.origin == msg.sender, "contracts not allowed to mint");
        SaleStage currentActiveSaleStage = getCurrentActiveSaleStage();
        require(
            currentActiveSaleStage != SaleStage.None,
            "no active sale right now"
        );
        require(userSelectedNumberOfTokens > 0, "numberOfTokens cannot be 0");
        if (currentActiveSaleStage == SaleStage.whitelist) {
            _mintwhitelist(
                proof,
                merkleNumberOfTokens,
                userSelectedNumberOfTokens
            );
        } else if (currentActiveSaleStage == SaleStage.publicSale) {
            _mintpublicSale(userSelectedNumberOfTokens);
        }
    }

    function _mintwhitelist(
        bytes32[] calldata proof,
        uint256 merkleNumberOfTokens,
        uint256 userSelectedNumberOfTokens
    ) internal {
        require(
            msg.value == whitelistMintPrice * userSelectedNumberOfTokens,
            "sent ether value incorrect"
        );
        require(
            proof.verify(
                _whitelistMerkleRoot,
                keccak256(abi.encodePacked(msg.sender, merkleNumberOfTokens))
            ),
            "failed to verify merkle root"
        );
        uint256 currentRemainingCount = remainingCount();
        uint256 refundAmount = 0;
        uint256 actualMintedQuantity = userSelectedNumberOfTokens;
        require(currentRemainingCount > 0, "sold out");

        if (currentRemainingCount < userSelectedNumberOfTokens) {
            // partially fill order
            refundAmount =
                (userSelectedNumberOfTokens - currentRemainingCount) *
                whitelistMintPrice;
            actualMintedQuantity = currentRemainingCount;
        }
        require(
            whitelistPurchased[msg.sender] + actualMintedQuantity <=
                merkleNumberOfTokens,
            "whitelisted user can only mint up to their allocated quota"
        );

        whitelistPurchased[msg.sender] += actualMintedQuantity;
        mintedQuantity += actualMintedQuantity;
        NFT(o2LandAddress).mint(msg.sender, actualMintedQuantity);
        if (refundAmount > 0) {
            payable(msg.sender).transfer(refundAmount);
        }
    }

    function _mintpublicSale(uint256 userSelectedNumberOfTokens) internal {
        require(
            msg.value == publicSaleMintPrice * userSelectedNumberOfTokens,
            "sent ether value incorrect"
        );
        uint256 currentRemainingCount = remainingCount();
        uint256 refundAmount = 0;
        uint256 actualMintedQuantity = userSelectedNumberOfTokens;
        require(currentRemainingCount > 0, "sold out");
        if (currentRemainingCount < userSelectedNumberOfTokens) {
            // partially fill order
            refundAmount =
                (userSelectedNumberOfTokens - currentRemainingCount) *
                publicSaleMintPrice;
            actualMintedQuantity = currentRemainingCount;
        }
        require(
            actualMintedQuantity <= maxMintQuantityPerTx,
            "exceeds max mint quantity per tx"
        );
        require(
            publicSalePurchased[msg.sender] + actualMintedQuantity <=
                maxMintQuantityPerAddress,
            "exceeds max mint quantity per addr"
        );
        publicSalePurchased[msg.sender] += actualMintedQuantity;
        mintedQuantity += actualMintedQuantity;
        NFT(o2LandAddress).mint(msg.sender, actualMintedQuantity);
        if (refundAmount > 0) {
            payable(msg.sender).transfer(refundAmount);
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
        uint256 _publicSaleAllocatedQuantity,
        uint256 _maxMintQuantityPerTx,
        uint256 _maxMintQuantityPerAddress,
        uint256 _maxTotalSoldQuantity,
        uint256 _whitelistMintPrice,
        uint256 _publicSaleMintPrice
    ) external onlyOwner {
        whitelistSaleStartTime = _whitelistSaleStartTime;
        whitelistSaleEndTime = _whitelistSaleEndTime;
        whitelistSaleAllocatedQuantity = _whitelistSaleAllocatedQuantity;
        publicSaleStartTime = _publicSaleStartTime;
        publicSaleEndTime = _publicSaleEndTime;
        publicSaleAllocatedQuantity = _publicSaleAllocatedQuantity;
        maxMintQuantityPerTx = _maxMintQuantityPerTx;
        maxMintQuantityPerAddress = _maxMintQuantityPerAddress;
        maxTotalSoldQuantity = _maxTotalSoldQuantity;
        whitelistMintPrice = _whitelistMintPrice;
        publicSaleMintPrice = _publicSaleMintPrice;
    }

    function withdraw(address to) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
    }
}
